
# Setup -------------------------------------------------------------------

## Libraries and functions -------------------------------------------------

library(here)
library(stringr)
library(dplyr)
library(tidyr)
library(purrr)
library(sf)
library(readxl)
library(readr)
source(here::here("R/utils.R"))
sf::sf_use_s2(FALSE)

# Function to cleanly import the Excel sheets
clean_sheet <- function(df) {
  
  # columns to change name
  vl_colnames <- c(
    "code_id" = "Cod_ID",
    "code_udh" = "UDH_Atlas",
    "name_udh" = "NOME_UDH",
    "code_region" = "Cod_Reg",
    "name_region" = "NOME_REG",
    "code_region" = "COD_ID",
    "name_region" = "Nomes_Regionais",
    "name_region" = "Nome_Regionais",
    "year" = "ANO",
    "code_metro" = "CODRM"
  )
  # columns to remove
  rm_cols <- c(
    "cod_mun", "codmun6", "nome_mun", "coduf", "nome_uf", "nome_rm"
    )
  
  df <- df |> 
    # Rename columns and drop some unwanted identifiers
    dplyr::rename(dplyr::any_of(vl_colnames)) |> 
    dplyr::rename_with(stringr::str_to_lower) |> 
    dplyr::select(-dplyr::any_of(rm_cols))
  
  df <- df |> 
    # Convert all columns from year to ihdm_r to numeric
    dplyr::mutate(dplyr::across(year:idhm_r, as.numeric))
  
  return(df)
  
}

# Function to aggregate a sf into a single polygon
make_city_border <- function(shape) {
  
  city_border <- try(
    shape %>%
      sf::st_make_valid() %>%
      dplyr::summarise(geometry = sf::st_union(.)) %>%
      sf::st_make_valid()
  )
  
  if (all(class(city_border) == "try-error")) {
    city_border <- data.frame()
  }
  
  return(city_border)
  
}

## Metro Region IDs --------------------------------------------------------

# Import IBGE identifiers for all Brazilian Metro Regions
id_metro <- geobr::read_metro_area()
id_metro <- as_tibble(st_drop_geometry(id_metro))
id_metro <- select(id_metro, code_muni, name_muni, code_state, name_metro)
# Simplify and shorten some names
id_metro <- id_metro |> 
  mutate(
    name_metro = case_when(
      str_detect(name_metro, "RIDE TERESINA") ~ "RIDE - Teresina",
      str_detect(name_metro, "RIDE - Reg") ~ "RIDE - Distrito Federal",
      TRUE ~ str_replace(name_metro, "Aglomeração Urbana", "AU")
    )
  )

# Import Atlas Files ------------------------------------------------------

# Find all path files
fl1 <- list.files(here("data-raw"), pattern = "^dados_", full.names = TRUE)
fl2 <- map(fl1, list.files, full.names = TRUE)
files_cities <- map(fl2, list.files, full.names = TRUE)

# Find path to UDH shapes
path_shape_udh <- sapply(files_cities, \(x) x[str_detect(x, "UDH_.+shp$")])
# Find path to Region Shapes
# OBS: not all RMs are aggregated by regions
path_shape_region <- sapply(files_cities, \(x) x[str_detect(x, "Regional_.+shp$")])
path_shape_region <- path_shape_region[sapply(path_shape_region, length) == 1]

# Find path to UDH data
path_data <- map(files_cities, \(x) x[str_detect(x, "Base UDH.+xlsx$")])
# Find path to Regional data
path_data_region <- map(files_cities, \(x) x[str_detect(x, "Base REGIONAL.+xlsx$")])
path_data_region <- path_data_region[sapply(path_data_region, length) == 1]

# Check if all elements are non-null
if (all(map_vec(path_data, length) == 1)) {
  message("Path to data OK.")
} else {
  stop("Check pathfiles to Excel sheets.")
}
if (all(map_vec(path_shape_udh, length) == 1)) {
  message("Path to Shapefiles OK.")
} else {
  stop("Check pathfiles to .shp files.")
}


## Dictionary --------------------------------------------------------------

# Named character vector to rename columns
vl_colnames <- c(
  "code_udh" = "UDH_ATLAS",
  "code_muni" = "CD_GEOCODM",
  "code_region" = "REGIONAL"
)

# Import data dictionary from Excel sheet
dictionary <- read_excel("data-raw/dictionary_atlas.xlsx", sheet = 1)
# Set levels for categories
lvls <- c(
  "HDI", "Demographic", "Demographic - Age group",
  "Income", "Income - Distribution", "Income - Poverty",
  "Education", "Work"
  )

dictionary <- dictionary |> 
  mutate(category = factor(category, levels = lvls)) |>
  arrange(category, variable)

## Import shape files ------------------------------------------------------

### UDHs --------------------------------------------------------------------

# Import all shape files
shape_udh <- map(path_shape_udh, st_read, quiet = TRUE)
# Clean all geometries
shape_udh <- map(shape_udh, clean_geometries)
# Stack all shape files
shape_udh <- bind_rows(shape_udh)

# Rename columns and select; join with identifiers
shape_udh <- shape_udh |> 
  rename(any_of(vl_colnames)) |> 
  select(any_of(names(vl_colnames))) |>
  mutate(
    code_muni = if_else(is.na(code_muni), str_sub(code_udh, 2, 8), code_muni),
    code_muni = as.numeric(code_muni)
  )

# Join with identifiers and manually solve two cases
shape_udh <- shape_udh |> 
  left_join(id_metro, by = "code_muni") |> 
  mutate(
    name_muni = if_else(code_muni == 5210000, "Inhumas", name_muni),
    name_muni = if_else(code_muni == 2207793, "Pau D'Arco do Piauí", name_muni),
    name_metro = if_else(code_muni == 5210000, "RM Salvador", name_metro),
    name_metro = if_else(code_muni == 2207793, "RIDE - Teresina", name_metro),
    # Get code_state as the two first digits in code_muni
    code_state = if_else(is.na(code_state), str_sub(code_muni, 1, 2), code_state),
    code_state = as.numeric(code_state)
  )

# Compute area of each UDH in squared km
shape_udh <- shape_udh %>%
  st_transform(crs = 32722) %>%
  mutate(
    area = st_area(.),
    area = as.numeric(area) / 1e6
    ) %>%
  st_transform(crs = 4326) %>%
  st_make_valid()

if (all(sapply(shape_udh, \(x) !all(is.na(x))))) {
  message("No NAs detected")
} else {
  stop("Some rows contain NAs.")
}

# Aggregate city shape files to get a city border

# Group by city and aggregate the polygons
city_border <- shape_udh |>
  group_by(code_muni) |>
  nest() |>
  mutate(city_border = map(data, \(geom) suppressMessages(make_city_border(geom))))
# Unnest, ungroup and convert to sf
city_border <- city_border |>
  unnest(cols = city_border) |>
  ungroup() |>
  select(-data) |>
  st_sf()
# Join with city identifiers and rearrange columns
city_border <- left_join(city_border, id_metro, by = "code_muni")
city_border <- select(city_border, code_muni, name_muni, code_state, name_metro)

### Regions -----------------------------------------------------------------

# Import, clean, and stack Region shape files
shape_region <- map(path_shape_region, st_read, quiet = TRUE)
shape_region <- map(shape_region, clean_geometries)
shape_region <- bind_rows(shape_region)

# Rename and select columns. The code_muni column is missing for Curitiba
shape_region <- shape_region |> 
  rename(any_of(vl_colnames)) |> 
  select(any_of(names(vl_colnames))) |>
  mutate(code_muni = if_else(is.na(code_muni), 4106902, as.numeric(code_muni)))

# Curitiba has a problem in code_region as well
curitiba_shape <- shape_region %>%
  filter(code_muni == 4106902) %>%
  mutate(
    digit = str_extract(code_region, "[0-9]+\\."),
    digit = str_remove(digit, "\\."),
    code_region = str_glue(
      "3{substr(code_muni, 1, 6)}{str_pad(digit, width = 2, side = 'left', pad = '0')}"
      )
  ) %>%
  select(-digit)

shape_region <- shape_region %>%
  filter(code_muni != 4106902) %>%
  bind_rows(curitiba_shape)

# Compute area of each UDH in squared km, convert back and make valid geometry
shape_region <- shape_region %>%
  st_transform(crs = 32722) %>%
  mutate(area = st_area(.), area = as.numeric(area) / 1e6) %>%
  st_transform(crs = 4326) %>%
  st_make_valid()

## Import data files -------------------------------------------------------

### UDHs --------------------------------------------------------------------

# Drop geometry from shape_udh. Use as UDHs identifiers
id_udhs <- as_tibble(st_drop_geometry(shape_udh))

# Import sheets
data_sheet <- map(path_data, readxl::read_excel)
# Clean all sheets
clean_udh <- map(data_sheet, clean_sheet)
# Stack all sheets
clean_udh <- bind_rows(clean_udh)
# Drop columns that are full NA
clean_udh <- select(clean_udh, where(~!all(is.na(.x))))
# Drop row that are full NA
clean_udh <- clean_udh %>% filter(rowMeans(is.na(.)) < 1)

# Join with identifiers and rearrange column order
clean_udh <- clean_udh |> 
  mutate(code_udh = as.character(code_udh)) |> 
  left_join(id_udhs, by = "code_udh") |> 
  select(
    code_udh,
    name_udh,
    code_muni,
    name_muni,
    code_state,
    code_metro,
    name_metro,
    everything()
    )

# Fix some problems with code_metro
clean_udh <- clean_udh %>%
  mutate(
    name_metro = case_when(
      code_metro == 63502 ~ "RM Campinas",
      code_metro == 62400 ~ "RM Natal",
      TRUE ~ name_metro
    )
  )
 
# Compute population density
clean_udh <- clean_udh |>
  mutate(densidade = pop / area)

# Sum population and simplify

# Select population columns, convert to long and sum
udh_pop <- clean_udh |> 
  select(code_udh, matches("(^mul)|(^hom)")) |> 
  pivot_longer(cols = -code_udh, names_to = "age_group", values_to = "pop") |>
  filter(!str_detect(age_group, "tot")) |> 
  mutate(
    sexo = str_extract(age_group, "^.*?(?=\\d)"),
    ages = str_remove(age_group, sexo)) |> 
  separate(
    col = ages,
    sep = "a",
    into = c("age_min", "age_max"),
    convert = TRUE
  )

udh_pop <- clean_udh |> 
  select(code_udh, matches("(^mulh)|(^hom)")) |> 
  pivot_longer(cols = -code_udh, names_to = "age_group", values_to = "pop") |>
  filter(!str_detect(age_group, "tot"))

# Extract only age group and sum
udh_total_pop <- udh_pop |> 
  mutate(age = str_remove_all(age_group, "(homem)|(homens)|(mulher)|(mulh)")) |> 
  summarise(total_pop = sum(pop, na.rm = TRUE), .by = c("code_udh", "age"))

# Split age column into age_min and age_max
udh_total_pop <- udh_total_pop |>
  separate("age", into = c("age_min", "age_max"), sep = "a", convert = TRUE)

# udh_pop <- udh_pop |> 
#   mutate(
#     # Extract all characters before the first digit
#     sex = str_extract(age_group, "(^homem)|(^homens)|(^mulher)|(^mulh)"),
#     # Remove 
#     age = str_remove_all(age_group, "(^homem)|(^homens)|(^mulher)|(^mulh)")) |> 
#   separate("age", into = c("age_min", "age_max"), sep = "a", convert = TRUE) |>
#   mutate(
#     sex = case_when(
#       sex %in% c("homem", "homens") ~ "male",
#       sex %in% c("mulh", "mulher") ~ "female"
#       )
#     ) |> 
#   select(-age_group)

df_age_group <- udh_total_pop |> 
  select(age_min, age_max) |> 
  distinct() |> 
  arrange(age_min) |> 
  mutate(
    age_label = case_when(
      age_max <= 19 ~ "Young (0-19)",
      age_min >= 20 & age_max <= 29 ~ "Young Adult (20-29)",
      age_min >= 30 & age_max <= 39 ~ "Adult (30-39)",
      age_min >= 40 & age_max <= 49 ~ "Adult (40-49)",
      age_min >= 50 & age_max <= 59 ~ "Adult (50-59)",
      age_min >= 60 & age_max <= 69 ~ "Adult (60-69)",
      age_min >= 70 & age_max <= 79 ~ "Elder (70-79)",
      age_min >= 80 ~ "Elder (80+)"
      ),
    age_group = c(1, 1, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8)
  )

udh_total_pop <- udh_total_pop |> 
  left_join(df_age_group, by = c("age_min", "age_max")) |> 
  summarise(
    total = sum(total_pop),
    .by = c("code_udh", "age_label", "age_group")
    )

tab_udh_pop <- udh_total_pop |> 
  pivot_wider(
    id_cols = "code_udh",
    names_from = "age_group",
    names_prefix = "pop_",
    values_from = "total"
    )

clean_udh <- left_join(clean_udh, tab_udh_pop, by = "code_udh")

### Regions -----------------------------------------------------------------

# Make identifiers for each region

# Aggregate ids for cities
id_cities <- distinct(id_udhs, code_muni, name_muni, code_state, name_metro)
# Drop geometry from shape file and join with city ids
id_region <- as_tibble(st_drop_geometry(shape_region))
id_region <- left_join(id_region, id_cities, by = "code_muni")

# Import, clean, and stack sheets.
data_sheet <- map(path_data_region, readxl::read_excel)
clean_region <- map(data_sheet, clean_sheet)
clean_region <- bind_rows(clean_region)
# Remove columns that are entirely NA
clean_region <- select(clean_region, where(~!all(is.na(.x))))

clean_region <- clean_region |> 
  mutate(code_region = as.character(code_region)) |> 
  left_join(id_region, by = "code_region") |>
  select(
    code_region,
    name_region,
    code_muni,
    name_muni,
    code_state,
    name_metro,
    everything()
  )

clean_region <- clean_region |> 
  mutate(densidade = pop / area)

# Import Metro Regions Data -----------------------------------------------

atlas_metro <- read_excel(here("data-raw/dados_bh/base final RM Belo Horizonte/A - Base 20 RMs 2000_2010.xlsx"))

clean_atlas_metro <- atlas_metro |>
  # Rename variables
  rename(code_metro = CODRM, name_metro = NOME_RM, year = ANO) |>
  # Convert all column names to lower
  rename_with(str_to_lower) |>
  # Convert columns to numeric and drop columns that are entirely NA
  mutate(across(year:idhm_r, as.numeric)) |>
  select(where(~!all(is.na(.x)))) |> 
  # Fix name metro and create an abbrev_state column
  mutate(
    abbrev_state = str_extract(name_metro, "\\([A-Z]{2}"),
    abbrev_state = str_remove(abbrev_state, "\\("),
    name_metro = str_remove(name_metro, " \\(.+"),
    name_metro = str_trim(name_metro)
  )

# Export ------------------------------------------------------------------

# [TEMP] select columns to simplify shape file
sub <- select(clean_udh, year, code_udh:t_env, all_of(dictionary$variable))
# Adjust income values for Inflation
income_variables <- c(
  "rdpc", "rdpc1", "rdpc2", "rdpc3", "rdpc4", "rdpc5", "rdpc10", "rdpct", "rind",
  "rmpob", "rpob", "corte1", "corte2", "corte3", "corte4", "corte9", "renocup")

sub <- sub |> 
  mutate(
    across(
      all_of(income_variables),
      ~ifelse(year == 2000, cpi_adjust00 * .x, cpi_adjust10 * .x)
      )
  )

subdata_region <- clean_region |> 
  select(code_region:t_env, any_of(dictionary$variable)) |> 
  mutate(
    across(
      all_of(income_variables),
      ~ifelse(year == 2000, cpi_adjust00 * .x, cpi_adjust10 * .x)
      )
    )

atlas_brasil <- left_join(select(shape_udh, code_udh), sub, by = "code_udh")

atlas_region <- left_join(
  select(shape_region, code_region),
  subdata_region,
  by = "code_region"
  )

# Last check (geometry)
atlas_brasil <- sf::st_make_valid(atlas_brasil)
atlas_region <- sf::st_make_valid(atlas_region)

qs::qsave(atlas_brasil, here::here("data/atlas_brasil.qs"))
qs::qsave(atlas_region, here::here("data/atlas_region.qs"))
readr::write_csv(dictionary, here::here("data/dictionary.csv"))
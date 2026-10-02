# Libraries ---------------------------------------------------------------

library(here)
library(plotly)
library(tmap)
tmap_mode(mode = "view")


# Data Input --------------------------------------------------------------

atlas <- readr::read_rds(here("data/atlas_brasil.rds"))
atlas_region <- readr::read_rds(here("data/atlas_region.rds"))
dict <- readr::read_csv(here("data/dictionary.csv"), show_col_types = FALSE)
cities <- readr::read_rds(here("data/shape_cities_metro.rds"))
centroids <- readr::read_csv(
  here("data/shape_centroid_capitals.csv"),
  show_col_types = FALSE
)
rmdata <- readr::read_csv(here("data/rmdata.csv"), show_col_types = FALSE)
dict_rm <- readr::read_csv(here("data/dict_rm.csv"), show_col_types = FALSE)

rmdata <- dplyr::filter(rmdata, year %in% c(2000, 2010, 2024))

# Brand tokens ------------------------------------------------------------

# Source of truth: ekioplot/inst/ekio-palettes.yaml. Kept as literals rather
# than a dependency on ekioplot so the app deploys from renv.lock alone.
ekio <- list(
  blue_700 = "#1E3A5F",
  blue_500 = "#3A71A8",
  blue_300 = "#82B5DA",
  gray_700 = "#373A3D",
  gray_500 = "#6A6E74",
  gray_400 = "#898E93",
  gray_300 = "#ABAEB3",
  gray_200 = "#CED0D4",
  white = "#FFFFFF"
)

ekio_font_family <- "Host Grotesk, Helvetica Neue, Helvetica, Arial, sans-serif"


# Choices -----------------------------------------------------------------

choice_years <- c(2000, 2010)

# Sequential and diverging palettes from ekioplot
# Source of truth: ekioplot/inst/ekio-palettes.yaml
choice_pal <- list(
  `Blue` = c(
    "#E8F6FF",
    "#B0D6F0",
    "#82B5DA",
    "#5194C8",
    "#3A71A8",
    "#2E5485",
    "#1E3A5F",
    "#152A44",
    "#0D1B2A"
  ),
  `Teal` = c(
    "#E2F9FA",
    "#ADDADC",
    "#7BBBBD",
    "#3C9E9F",
    "#097E7D",
    "#00605E",
    "#004342",
    "#013031",
    "#051F20"
  ),
  `Blue-Orange` = c(
    "#2E5485",
    "#3A71A8",
    "#82B5DA",
    "#B0D6F0",
    "#F5F3EF",
    "#F6C59F",
    "#E19D6A",
    "#AB5000",
    "#863900"
  ),
  `Teal-Orange` = c(
    "#00605E",
    "#097E7D",
    "#7BBBBD",
    "#ADDADC",
    "#F5F3EF",
    "#F6C59F",
    "#E19D6A",
    "#AB5000",
    "#863900"
  )
)

choice_type <- list(
  `Basic` = "pretty",
  `Natural Breaks (Jenks)` = "fisher",
  `Cluster (Hierarchical)` = "hclust"
)

metro_choice_region <- list(
  `Belo Horizonte` = "RM Belo Horizonte",
  `Curitiba` = "RM Curitiba",
  `Distrito Federal` = "RIDE - Distrito Federal",
  `Fortaleza` = "RM Fortaleza",
  `Grande Vitória` = "RM Grande Vitória",
  `Maceió` = "RM Maceió",
  `Manaus` = "RM Manaus",
  `Natal` = "RM Natal",
  `Porto Alegre` = "RM Porto Alegre",
  `Recife` = "RM Recife",
  `RIDE Petrolina` = "RIDE Petrolina/Juazeiro Região Administrativa Integrada de Desenvolvimento do Polo Petrolina/PE e Juazeiro/BA",
  `Rio de Janeiro` = "RM Rio de Janeiro",
  `São Paulo` = "RM São Paulo",
  `Sorocaba` = "RM de Sorocaba",
  `Teresina` = "RIDE - Teresina",
  `Vale do Rio Cuiabá` = "RM Vale do Rio Cuiabá"
)

metro_choice_udh <- list(
  `Baixada Santista` = "RM Baixada Santista",
  `Belém` = "RM Belém",
  `Belo Horizonte` = "RM Belo Horizonte",
  `Caetés` = "RM de Caetés",
  `Campinas` = "RM Campinas",
  `Curitiba` = "RM Curitiba",
  `Distrito Federal` = "RIDE - Distrito Federal",
  `Florianópolis` = "RM Florianópolis",
  `Fortaleza` = "RM Fortaleza",
  `Goiânia` = "RM Goiânia",
  `Grande Vitória` = "RM Grande Vitória",
  `Maceió` = "RM Maceió",
  `Manaus` = "RM Manaus",
  `Natal` = "RM Natal",
  `Porto Alegre` = "RM Porto Alegre",
  `Recife` = "RM Recife",
  `RIDE Petrolina` = "RIDE Petrolina/Juazeiro Região Administrativa Integrada de Desenvolvimento do Polo Petrolina/PE e Juazeiro/BA",
  `Rio de Janeiro` = "RM Rio de Janeiro",
  `Salvador` = "RM Salvador",
  `São Luís` = "RM Grande São Luís",
  `São Paulo` = "RM São Paulo",
  `Sorocaba` = "RM de Sorocaba",
  `Teresina` = "RIDE - Teresina",
  `Vale do Paraíba e Litoral Norte` = "RM do Vale do Paraíba e Litoral Norte",
  `Vale do Rio Cuiabá` = "RM Vale do Rio Cuiabá"
)

# UI sees the names, server sees the elements
choice_metro_regions <- list(
  `Belém` = "RM Belém",
  `Belo Horizonte` = "RM Belo Horizonte",
  `Baixada Santista` = "RM Baixada Santista",
  Campinas = "RM Campinas",
  `Vale do Rio Cuiabá` = "RM Vale do Rio Cuiabá",
  Curitiba = "RM Curitiba",
  `Distrito Federal` = "RIDE - Distrito Federal",
  Florianópolis = "RM Florianópolis",
  `Fortaleza` = "RM Fortaleza",
  Goiânia = "RM Goiânia",
  Salvador = "RM Salvador",
  `Maceió` = "RM Maceió",
  `Caetés` = "RM de Caetés",
  Manaus = "RM Manaus",
  `Natal` = "RM Natal",
  `Porto Alegre` = "RM Porto Alegre",
  `RIDE Petrolina` = "RIDE Petrolina/Juazeiro Região Administrativa Integrada de Desenvolvimento do Polo Petrolina/PE e Juazeiro/BA",
  `Recife` = "RM Recife",
  `Rio de Janeiro` = "RM Rio de Janeiro",
  `São Luís` = "RM Grande São Luís",
  `Sorocaba` = "RM de Sorocaba",
  `São Paulo` = "RM São Paulo",
  Teresina = "RIDE - Teresina",
  `Vale do Paraíba e Litoral Norte` = "RM do Vale do Paraíba e Litoral Norte",
  `Grande Vitória` = "RM Grande Vitória"
)

df_metros <- tibble::tibble(
  name_metro = unlist(choice_metro_regions),
  name_label = names(choice_metro_regions),
  is_region = ifelse(name_metro %in% metro_choice_region, 1L, 0L)
)

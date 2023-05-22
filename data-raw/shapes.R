library(geobr)
library(tidyr)
library(dplyr)
library(purrr)
library(stringr)
library(sf)
source(here::here("R/utils.R"))

# Import IBGE identifiers for all Brazilian Metro Regions
id_metro <- geobr::read_metro_area()
id_metro <- as_tibble(st_drop_geometry(id_metro))
id_metro <- select(id_metro, code_muni, name_muni, code_state, name_metro)
# Simplify/shorten the names of some metro regions
id_metro <- id_metro |> 
  mutate(
    name_metro = case_when(
      str_detect(name_metro, "RIDE TERESINA") ~ "RIDE - Teresina",
      str_detect(name_metro, "RIDE - Reg") ~ "RIDE - Distrito Federal",
      TRUE ~ str_replace(name_metro, "Aglomeração Urbana", "AU")
    )
  )

# Import IBGE shape files for all cities in Brazil
cities_shapes <- read_municipality(code_muni = "all", year = 2020, simplified = FALSE)
# Filter only cities that are part of some metro region and clean geometries
cities <- unique(id_metro$code_muni)
cities_shapes <- filter(cities_shapes, code_muni %in% cities)
cities_shapes <- clean_geometries(cities_shapes)
# Join shape file with the name of the metropolitan region
cities_metro <- left_join(
  cities_shapes,
  dplyr::select(id_metro, code_muni, name_metro),
  by = "code_muni"
  )

#' Get the centroid for some metropolitan regions
#' OBS: most metro regions are named after their main city, usually the capital city
#' of the state. I filter all metro regions names that match the name of a city
#' and compute the centroid of this city.

#' Filter metro regions that match a city name
#' OBS: code could be made cleaner without the nesting, grouping, unnesting, ungrouping
capital_metro <- cities_metro |> 
  group_by(name_metro) |>  
  nest() |> 
  mutate(capital = map(data, \(x) dplyr::filter(x, str_detect(name_metro, name_muni)))) |> 
  unnest(capital) |> 
  ungroup()
# Get the centroids and save as columns x (lng) and y (lat)
capital_metro <- capital_metro %>%
  select(name_metro, code_muni, name_muni, geom) %>%
  st_as_sf() %>%
  mutate(
    x = st_coordinates(st_centroid(.))[, 1],
    y = st_coordinates(st_centroid(.))[, 2]
  )

# Simplify output
capital_metro <- capital_metro %>%
  st_drop_geometry() %>%
  select(name_metro, x, y)

# Simplify output and make sure geometries are valid
cities_metro <- dplyr::select(cities_metro, code_muni, name_metro)
cities_metro <- sf::st_make_valid(cities_metro)

# Export all shapes
qs::qsave(cities_metro, here::here("data/shape_cities_metro.qs"))
readr::write_csv(capital_metro, here::here("data/shape_centroid_capitals.csv"))
readr::write_csv(id_metro, here::here("data/id_metro_regions.csv"))
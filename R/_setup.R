
# Libraries ---------------------------------------------------------------

library(here)
library(plotly)
library(tmap)
tmap_mode(mode = "view")


# Data Input --------------------------------------------------------------

atlas <- readRDS(here("data/atlas_brasil.rds"))
atlas_region <- readRDS(here("data/atlas_region.rds"))
dict <- readr::read_csv(here("data/dictionary.csv"))
cities <- readRDS(here("data/shape_cities_metro.rds"))
centroids <- readr::read_csv(here("data/shape_centroid_capitals.csv"))
rmdata <- readr::read_csv(here("data/rmdata.csv"))
dict_rm <- readr::read_csv(here("data/dict_rm.csv"))

rmdata <- dplyr::filter(rmdata, year %in% c(2000, 2010, 2024))

# Choices -----------------------------------------------------------------

choice_years <- c(2000, 2010)

# Sequential and diverging palettes sourced from the EKIO brand identity
choice_pal <- list(
  `EKIO Blue` = c(
    "#EEF5FA", "#D4E8F5", "#A8D0E8", "#7EB6D8", "#4A90C2",
    "#3A6EA5", "#2B4C7E", "#1E3A5F", "#0D1B2A"
  ),
  `EKIO Teal` = c(
    "#E6FFFA", "#B2F5EA", "#81E6D9", "#4FD1C5", "#38B2AC",
    "#319795", "#2C7A7B", "#285E61", "#234E52"
  ),
  `EKIO Blue-Orange` = c(
    "#0D1B2A", "#1E3A5F", "#3A6EA5", "#7EB6D8", "#D4E8F5",
    "#F5F0EB",
    "#FEEBC8", "#F6AD55", "#DD6B20", "#9C4221", "#7B341E"
  ),
  `EKIO Teal-Orange` = c(
    "#234E52", "#2C7A7B", "#38B2AC", "#81E6D9", "#E6FFFA",
    "#F5F0EB",
    "#FEEBC8", "#F6AD55", "#DD6B20", "#9C4221", "#7B341E"
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
  `Belém` = "RM Belém", `Belo Horizonte` = "RM Belo Horizonte", 
  `Baixada Santista` = "RM Baixada Santista", Campinas = "RM Campinas", 
  `Vale do Rio Cuiabá` = "RM Vale do Rio Cuiabá", Curitiba = "RM Curitiba", 
  `Distrito Federal` = "RIDE - Distrito Federal", Florianópolis = "RM Florianópolis", 
  `Fortaleza` = "RM Fortaleza", Goiânia = "RM Goiânia", Salvador = "RM Salvador", 
  `Maceió` = "RM Maceió", `Caetés` = "RM de Caetés", Manaus = "RM Manaus", 
  `Natal` = "RM Natal", `Porto Alegre` = "RM Porto Alegre",
  `RIDE Petrolina` = "RIDE Petrolina/Juazeiro Região Administrativa Integrada de Desenvolvimento do Polo Petrolina/PE e Juazeiro/BA", 
  `Recife` = "RM Recife", `Rio de Janeiro` = "RM Rio de Janeiro", 
  `São Luís` = "RM Grande São Luís", `Sorocaba` = "RM de Sorocaba", 
  `São Paulo` = "RM São Paulo", Teresina = "RIDE - Teresina", 
  `Vale do Paraíba e Litoral Norte` = "RM do Vale do Paraíba e Litoral Norte", 
  `Grande Vitória` = "RM Grande Vitória"
)

df_metros <- tibble::tibble(
  name_metro = unlist(choice_metro_regions),
  name_label = names(choice_metro_regions),
  is_region = ifelse(name_metro %in% metro_choice_region, 1L, 0L)
)
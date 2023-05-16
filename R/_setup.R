
# Libraries ---------------------------------------------------------------

library(here)
library(plotly)
library(tmap)
library(tmaptools)
tmap_mode(mode = "view")


# Data Input --------------------------------------------------------------

atlas <- readr::read_rds(here("data/atlas_brasil.rds"))
atlas_region <- readr::read_rds(here("data/atlas_region.rds"))
dict <- readr::read_rds(here("data/dictionary.rds"))
cities <- readr::read_rds(here("data/shape_cities_metro.rds"))
centroids <- readr::read_rds(here("data/shape_centroid_capitals.rds"))
rmdata <- readr::read_rds(here("data/rmdata.rds"))

# Choices -----------------------------------------------------------------

choice_years <- c(2000, 2010)

choice_pal <- list(
  `Viridis` = "viridis",
  `Inferno` = "inferno",
  `Red-Blue` = "RdBu",
  `Brown-Green` = "BrBG"
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
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

# Choices -----------------------------------------------------------------

choice_years <- c(2000, 2010)

# Sequential and diverging palettes from ekioplot
choice_pal <- list(
  `Blue` = c(
    "#E8F6FF",
    "#B1D8F2",
    "#84B8DD",
    "#5597CC",
    "#3E76AC",
    "#305687",
    "#1E3A5F",
    "#152A44",
    "#0D1B2A"
  ),
  `Teal` = c(
    "#E2F9FA",
    "#AFDCDD",
    "#7EBEC0",
    "#40A2A3",
    "#158281",
    "#006261",
    "#004342",
    "#013031",
    "#051F20"
  ),
  `Blue-Orange` = c(
    "#152A44",
    "#305687",
    "#5597CC",
    "#B1D8F2",
    "#F5F3EF",
    "#F7C7A0",
    "#D3742A",
    "#893A00",
    "#471904"
  ),
  `Teal-Orange` = c(
    "#013031",
    "#006261",
    "#40A2A3",
    "#AFDCDD",
    "#F5F3EF",
    "#F7C7A0",
    "#D3742A",
    "#893A00",
    "#471904"
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

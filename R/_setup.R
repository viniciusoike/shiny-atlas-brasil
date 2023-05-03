library(here)
library(tmap)
library(tmaptools)
tmap_mode(mode = "view")

atlas <- readr::read_rds(here("data/atlas_brasil.rds"))
dict <- readr::read_rds(here("data/dictionary.rds"))
cities <- readr::read_rds(here("data/shape_cities_metro.rds"))
centroids <- readr::read_rds(here("data/shape_centroid_capitals.rds"))

choice_metro_regions <- c(
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

choice_metro_regions <- choice_metro_regions[order(names(choice_metro_regions))]

choice_years <- c(2000, 2010)

# choice_category <- list(
#   `Demographic` = c("pop",
#     "espvida", "fectot", "mort1", "mort5", "sobre40", "sobre60", "raz_dep", "t_env"
#     ),
#   `Income` = c(
#     "rdpc", "rdpc1", "rdpc10", "rdpc2", "rdpc3", "rdpc4", "rdpc5", "rdpct",
#     "rind", "rmpob", "rpob", "theil"),
#   `HDI` = c(
#     "idhm_e", "idhm_r", "idhm_l", "idhm"
#   )
# )
# 
# choice_category <- tibble::enframe(choice_category, name = "category", value = "variable")
# choice_category <- tidyr::unnest(choice_category, variable)

choice_pal <- c(
  "Viridis" = "viridis",
  "Inferno" = "inferno",
  "Red-Blue" = "RdBu",
  "Brown-Green" = "BrBG"
)

choice_type <- c(
  "Basic" = "pretty",
  "Natural Breaks (Jenks)" = "fisher",
  "Cluster (Hierarchical)" = "hclust"
)

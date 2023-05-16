clean_geometries <- function(shp) {
  
  shp <- sf::st_transform(shp, crs = 4326)
  shp <- sf::st_make_valid(shp)
  return(shp)
  
}
# Accumulated consumer price inflation from Aug/2010-Jan/2023
cpi_adjust <- 2.09203170
# End of period exchange rate (31/01/2023)
brl_usd <- 5.09

# Gets ordered list of metropolitan regions based on geographical resolution
get_choice_metro <- function(geo = "UDH") {
  
  stopifnot(any(geo %in% c("UDH", "Region")))
  
  if (geo == "UDH") {
    choices <- na.omit(unique(atlas$name_metro))
  } else if (geo == "Region") {
    choices <- na.omit(unique(atlas_region$name_metro))
  }
  
  out <- choice_metro_regions[choice_metro_regions %in% choices]
  out <- out[order(names(out))]
  
  return(out)
  
}

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

aboutme_en <-
  "My name is Vinicius Oike Reginatto and I hold a Master's degree in Economics
  from the University of São Paulo (USP), one of the most prestigious universities in Brazil.
  Since graduating, I've gained experience in both the tech and consulting sectors, working primarily in real estate.
  I'm particularly passionate about economics, urbanism, and real estate; I enjoy making apps and data science tools in R to solve real-world problems."

about_app <- 
  "Consolidated as one of the largest tools for disclosing information about human development in Brazil, the Atlas of Human Development in Brazil platform has the goal of offering, in an uncomplicated manner, broad access to different statistic information that reveal characteristics and social inequalities in the Brazilian territory."
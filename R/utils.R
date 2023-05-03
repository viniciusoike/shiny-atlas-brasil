clean_geometries <- function(shp) {
  
  shp <- sf::st_transform(shp, crs = 4326)
  shp <- sf::st_make_valid(shp)
  return(shp)
  
}
# Accumulated consumer price inflation from Aug/2010-Jan/2023
cpi_adjust <- 2.09203170
# End of period exchange rate (31/01/2023)
brl_usd <- 5.09
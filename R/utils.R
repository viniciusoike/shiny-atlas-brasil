clean_geometries <- function(shp) {
  
  shp <- sf::st_transform(shp, crs = 4326)
  shp <- sf::st_make_valid(shp)
  return(shp)
  
}
# Accumulated consumer price inflation from Aug/2010-Jan/2023
cpi_adjust00 <- 3.96710740
cpi_adjust10 <- 2.09203170
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

aboutme_en <-
  "My name is Vinicius Oike Reginatto, and I hold a Master's degree in Economics
from the University of São Paulo (USP), one of the most prestigious universities in Brazil.
 Since graduating, I have gained experience in both the tech and consulting sectors, primarily in real estate.
 I am particularly passionate about economics, urbanism, and real estate.
 I enjoy creating apps and data science tools in R to solve real-world problems."

about_app1 <-
  "The Atlas of Human Development is a comprehensive collection of development indicators in Brazil.
 It provides access to information that reveals socioeconomic realities and inequalities.
 The data is compiled from IBGE's decennial Census and yearly PNAD/C survey. It is
the result of a collaborative effort between PNUD (UN), IPEA, and FJP."

about_app2 <-
  "The interactive map displays both regions and UDHs (human development units) for the
major metropolitan regions of Brazil in 2000 and 2010. Income values have been
adjusted for inflation up to January 2023. The map options allow for different forms of aggregation
and color palettes. The ranking tool ranks metro regions and includes more recent data from PNAD.
Finally, the download data tool provides a convenient way to download all of the data used in this app."

about_app3 <-
  "The construction of this app required extensive data cleaning, classification, and
standardization. I chose a smaller subset of variables to keep the app manageable
and to avoid overwhelming the user with options. For reference, the complete Atlas UDH dataset
contains almost 230 variables. This smaller subset of variables also allowed me to better
integrate the different Atlas datasets. In the future, I will provide more details about this process on my
blog."
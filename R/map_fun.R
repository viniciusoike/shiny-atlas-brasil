
setup_map <- function(metro, year_sel = 2010) {
  
  # Filter the UDH data from Atlas Brasil
  udh <- atlas |> 
    dplyr::filter(
      name_metro == choice_metro_regions[[metro]],
      year == year_sel
      )
  # Get the city borders for this metropolitan region
  border <- cities |> 
    dplyr::filter(name_metro == choice_metro_regions[[metro]])
  # Get the city centroid
  city_center <- centroids |> 
    dplyr::filter(name_metro == choice_metro_regions[[metro]])
  # If there is no city centroid return a NULL
  if (nrow(city_center) == 1) {
    center <- c(city_center$x, city_center$y)
  } else {
    center <- NULL
  }
  
  out <- list(
    udh = udh,
    city_border = border,
    city_center = center
  )
  
  return(out)
  
}

map_atlas <- function(
    metro = "Porto Alegre",
    year_sel = 2010,
    pal = "Brown-Green",
    type = "Natural Breaks (Jenks)",
    var_sel = "HDI (overall)",
    n = 5) {
  
  # Get shape file and variables
  dat <- setup_map(metro, year_sel)
  # Get the name of the variable to map
  map_variable <- unique(subset(dict, title_var_en == var_sel)$variable)
  # Get the number of digits to show
  digits <- unique(subset(dict, variable == map_variable)$digits)
  
  # Experimental: different popup variables based on the mapped variable
  if (stringr::str_detect(map_variable, "^idh")) {

    popup_vars <- c(
      "IDHM: " = "idhm",
      "Education: " = "idhm_e",
      "Health: " = "idhm_l",
      "Income: " = "idhm_r"
    )

  } else {
    popup_vars <- map_variable
    names(popup_vars) <- paste0(var_sel, ": ")
  }

  # Get parameters to define the center of the map
  if (is.null(dat$city_center)) {
    map_center <- 11
  } else {
    map_center <- c(dat$city_center, 11)
  }
  
  # Map
  tm_shape(dat$udh) +
    tm_fill(
      col = map_variable,
      palette = choice_pal[pal],
      style = choice_type[type],
      n = n,
      alpha = 0.6,
      id = "name_udh",
      title = var_sel,
      popup.vars = popup_vars,
      popup.format = list(digits = digits)
    ) +
    tm_borders(lwd = 1, col = "gray80") +
    # City border
    tm_shape(dat$city_border) +
    tm_borders(col = "gray50", lwd = 1.5) +
    # Server and view
    tm_basemap(server = "CartoDB.Positron") +
    tm_view(set.view = map_center)
  
}

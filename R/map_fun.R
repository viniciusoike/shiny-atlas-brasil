setup_map <- function(rm, y, geo = "UDH") {
  
  # current_metro <- subset(df_metros, name_label == rm)$name_metro
  # current_metro <- as.character(unique(current_metro))
  
  current_metro <- as.character(unique(rm))
  
  if (geo == "UDH") {
    # Filter the UDH data from Atlas Brasil
    metro_atlas <- subset(atlas, name_metro == current_metro & year == y)
  } else if (geo == "Region") {
    # Filter the Region data from Atlas Brasil
    metro_atlas <- subset(atlas_region, name_metro == current_metro & year == y)
  }
  
  # Get the city borders for this metropolitan region
  border <- subset(cities, name_metro == current_metro)
  # Get the city centroid
  city_center <- subset(centroids, name_metro == current_metro)
  # If there is no city centroid return a NULL
  if (current_metro == "RM Rio de Janeiro") {
    center <- c(-43.187866, -22.910667)
  } else if (nrow(city_center) == 1) {
    center <- c(city_center$x, city_center$y)
  } else {
    center <- NULL
  }

  out <- list(
    atlas = metro_atlas,
    city_border = border,
    city_center = center
  )

  return(out)
  
}

map_atlas <- function(
    metro = "Porto Alegre",
    year_sel = 2010,
    geo = "UDH",
    pal = "Brown-Green",
    type = "Natural Breaks (Jenks)",
    var_sel = "HDI (overall)",
    n = 5) {

  # Get shape file and variables
  dat <- setup_map(rm = metro, y = year_sel, geo = geo)
  # Get the name of the variable to map
  map_variable <- unique(subset(dict, title_var_en == var_sel)$variable)
  # Get the number of digits to show
  digits <- unique(subset(dict, variable == map_variable)$digits)
  # Get the labels for the popup
  id <- ifelse(geo == "UDH", "name_udh", "name_region")
  
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
  
  if (metro == "Rio de Janeiro") {
    dat$atlas <- sf::st_make_valid()
  }
  
  # Map
  tm_shape(dat$atlas) +
    tm_fill(
      col = map_variable,
      palette = choice_pal[[pal]],
      style = choice_type[[type]],
      n = n,
      alpha = 0.6,
      id = id,
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

setup_map <- function(rm, y, geo = "UDH") {
  current_metro <- as.character(unique(rm))

  if (geo == "UDH") {
    metro_atlas <- subset(atlas, name_metro == current_metro & year == y)
  } else if (geo == "Region") {
    metro_atlas <- subset(atlas_region, name_metro == current_metro & year == y)
  }

  border <- subset(cities, name_metro == current_metro)
  city_center <- subset(centroids, name_metro == current_metro)

  if (current_metro == "RM Rio de Janeiro") {
    center <- c(-43.187866, -22.910667)
  } else if (nrow(city_center) == 1) {
    center <- c(city_center$x, city_center$y)
  } else {
    center <- NULL
  }

  list(
    atlas = metro_atlas,
    city_border = border,
    city_center = center
  )
}

map_atlas <- function(
  metro = "Porto Alegre",
  year_sel = 2010,
  geo = "UDH",
  pal = "EKIO Blue-Orange",
  type = "Natural Breaks (Jenks)",
  var_sel = "HDI (overall)",
  n = 5
) {
  dat <- setup_map(rm = metro, y = year_sel, geo = geo)
  map_variable <- unique(subset(dict, title_var_en == var_sel)$variable)
  digits <- unique(subset(dict, variable == map_variable)$digits)
  id <- ifelse(geo == "UDH", "name_udh", "name_region")

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

  map_center <- if (is.null(dat$city_center)) 11 else c(dat$city_center, 11)

  if (metro == "Rio de Janeiro") {
    dat$atlas <- sf::st_make_valid(dat$atlas)
  }

  tm_shape(dat$atlas) +
    tm_polygons(
      fill = map_variable,
      fill.scale = tm_scale_intervals(
        values = choice_pal[[pal]],
        style = choice_type[[type]],
        n = n
      ),
      fill.legend = tm_legend(title = var_sel),
      fill_alpha = 0.6,
      col = "gray80",
      lwd = 1,
      id = id,
      popup.vars = popup_vars,
      popup.format = list(digits = digits)
    ) +
    tm_shape(dat$city_border) +
    tm_borders(col = "gray50", lwd = 1.5) +
    tm_basemap(server = "CartoDB.Positron") +
    tm_view(set_view = map_center)
}

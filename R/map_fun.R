#' Is the app running on a deployment server?
#'
#' shinyapps.io and Posit Connect both set `R_CONFIG_ACTIVE`; Shiny Server sets
#' `SHINY_SERVER_VERSION`. None of them are set by `shiny::runApp()` locally.
is_deployed <- function() {
  Sys.getenv("R_CONFIG_ACTIVE") %in%
    c("shinyapps", "rsconnect") ||
    nzchar(Sys.getenv("SHINY_SERVER_VERSION"))
}

#' Carto API key for the current environment
#'
#' Deployments read `CARTO_BASEMAP_SHINY`, local sessions read
#' `CARTO_BASEMAP_INTERNAL_KEY`. The two never substitute for each other, so a
#' deploy that is missing its secret does not fall back to the internal key.
carto_key <- function() {
  var <- if (is_deployed()) {
    "CARTO_BASEMAP_SHINY"
  } else {
    "CARTO_BASEMAP_INTERNAL_KEY"
  }
  Sys.getenv(var)
}

#' Pick the basemap tile server
#'
#' Carto requires an API key for its basemaps. With a key the map uses Positron;
#' without one it falls back to a provider that serves tiles without a key, so
#' the map never renders the Carto watermark.
#'
#' The URL is built by hand because `leaflet::addProviderTiles()` drops the key
#' (rstudio/leaflet#965). A `server` starting with `http` makes tmap call
#' `leaflet::addTiles()` instead, which keeps the query string. Carto reads the
#' key from `key=`; `api_key=` returns the watermark tile.
basemap_server <- function() {
  key <- carto_key()

  if (!nzchar(key)) {
    return("Esri.WorldGrayCanvas")
  }

  paste0(
    "https://basemaps.cartocdn.com/rastertiles/light_all/{z}/{x}/{y}.png?key=",
    key
  )
}

#' Attribution line for the basemap in use
basemap_credits <- function() {
  if (nzchar(carto_key())) {
    "\u00a9 OpenStreetMap contributors \u00a9 CARTO"
  } else {
    "Tiles \u00a9 Esri"
  }
}

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
  metro = "RM Porto Alegre",
  year_sel = 2010,
  geo = "UDH",
  pal = "Blue-Orange",
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

  if (metro == "RM Rio de Janeiro") {
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
      fill_alpha = 0.7,
      col = ekio$gray_300,
      lwd = 0.8,
      id = id,
      popup.vars = popup_vars,
      popup.format = list(digits = digits)
    ) +
    tm_shape(dat$city_border) +
    tm_borders(col = ekio$gray_500, lwd = 2) +
    tm_basemap(server = basemap_server()) +
    tm_credits(basemap_credits()) +
    tm_view(set_view = map_center)
}

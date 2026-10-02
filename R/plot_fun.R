#' Setup the plot data
#'
#' Prepares the data for the `plot_rank()` function.
#'
#' @param x String with the (labelled) variable name
setup_plot <- function(x) {
  # Get the name of the variable column
  variable <- unique(subset(dict_rm, title_var_en == x)$variable)
  # Takes only the selected variable and converts to wide
  df <- rmdata |>
    tidyr::pivot_wider(
      id_cols = "name_metro",
      names_from = "year",
      names_prefix = "year_",
      values_from = dplyr::all_of(variable)
    )

  # Orders name_metro by the 2024 PNAD estimate, falling back to the 2010
  # census value for metros without 2024 coverage (e.g. Aracaju, João
  # Pessoa, Macapá), so they rank by their real value instead of being
  # pushed to one end by a missing sort key
  sort_key <- dplyr::coalesce(df[["year_2024"]], df[["year_2010"]])
  lvls <- df[["name_metro"]][order(sort_key)]
  # Converts to factor and arranges
  df <- df |>
    mutate(name_metro = factor(name_metro, levels = lvls)) |>
    arrange(name_metro)

  return(df)
}

#' Create ranked dumbbell plots
#'
#' Plots a variable using dumbbell plots
#'
#' @param x String with the (labelled) variable name
plot_rank <- function(x) {
  title <- x
  plot_dat <- setup_plot(x)

  plot_ly(plot_dat) %>%
    add_segments(
      x = ~year_2000,
      xend = ~year_2010,
      y = ~name_metro,
      yend = ~name_metro,
      color = I(ekio$gray_400),
      showlegend = FALSE
    ) %>%
    add_segments(
      x = ~year_2010,
      xend = ~year_2024,
      y = ~name_metro,
      yend = ~name_metro,
      color = I(ekio$gray_400),
      showlegend = FALSE
    ) %>%
    add_markers(
      x = ~year_2000,
      y = ~name_metro,
      marker = list(size = 10),
      name = "2000",
      color = I(ekio$blue_300)
    ) %>%
    add_markers(
      x = ~year_2010,
      y = ~name_metro,
      marker = list(size = 10),
      name = "2010",
      color = I(ekio$blue_500)
    ) %>%
    add_markers(
      x = ~year_2024,
      y = ~name_metro,
      marker = list(size = 10),
      name = "2024",
      color = I(ekio$blue_700)
    ) %>%
    layout(
      title = list(
        text = paste0("Ranking: ", title),
        font = list(color = ekio$blue_700, size = 18)
      ),
      paper_bgcolor = ekio$white,
      plot_bgcolor = ekio$white,
      xaxis = list(
        title = title,
        gridcolor = ekio$gray_200,
        zeroline = FALSE,
        linecolor = ekio$gray_300,
        tickcolor = ekio$gray_300
      ),
      yaxis = list(
        title = "",
        gridcolor = ekio$gray_200,
        zeroline = FALSE,
        linecolor = ekio$gray_300,
        tickcolor = ekio$gray_300
      ),
      legend = list(orientation = "h", x = 0, y = 1.04),
      margin = list(t = 60),
      hoverlabel = list(
        bgcolor = ekio$white,
        bordercolor = ekio$gray_300,
        font = list(family = ekio_font_family, color = ekio$gray_700)
      ),
      font = list(
        family = ekio_font_family,
        color = ekio$gray_700,
        size = 14
      )
    )
}

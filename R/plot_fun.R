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

  # Orders name_metro by the variable's values in 2000
  lvls <- df[["name_metro"]][order(df[["year_2000"]])]
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
      color = I("gray60"),
      showlegend = FALSE
    ) %>%
    add_segments(
      x = ~year_2010,
      xend = ~year_2024,
      y = ~name_metro,
      yend = ~name_metro,
      color = I("gray60"),
      showlegend = FALSE
    ) %>%
    add_markers(
      x = ~year_2000,
      y = ~name_metro,
      marker = list(size = 10),
      name = "2000",
      color = I("#A8D0E8")
    ) %>%
    add_markers(
      x = ~year_2010,
      y = ~name_metro,
      marker = list(size = 10),
      name = "2010",
      color = I("#3A6EA5")
    ) %>%
    add_markers(
      x = ~year_2024,
      y = ~name_metro,
      marker = list(size = 10),
      name = "2024",
      color = I("#1E3A5F")
    ) %>%
    layout(
      title = paste0("Ranking: ", title),
      xaxis = list(title = title),
      yaxis = list(title = ""),
      margin = list(t = 40),
      font = list(
        family = "Helvetica Neue, Helvetica, Arial, sans-serif",
        size = 14
      )
    )
}

setup_plot <- function(x) {
  
  # Get the name of the variable to map
  variable <- unique(subset(dict, title_var_en == x)$variable)
  
  df <- rmdata |> 
    tidyr::pivot_wider(
      id_cols = "name_metro",
      names_from = "year",
      names_prefix = "year_",
      values_from = dplyr::all_of(variable)
    )
  
  lvls <- df[["name_metro"]][order(df[["year_2000"]])]
  
  df <- df %>%
    mutate(name_metro = factor(name_metro, levels = lvls))
  
  return(df)
  
}

plot_rank <- function(x) {

  title = x
  
  df = setup_plot(x)
  
  plot_ly(df) %>%
    add_segments(
      x = ~year_2000,
      xend = ~year_2010,
      y = ~name_metro,
      yend = ~name_metro,
      color = I("gray60"),
      showlegend = FALSE) %>%
    add_markers(
      x = ~year_2000,
      y = ~name_metro,
      marker = list(size = 10),
      name = "2000",
      color = I("#83c5be")
    ) %>%
    add_markers(
      x = ~year_2010,
      y = ~name_metro,
      marker = list(size = 10),
      name = "2010",
      color = I("#006d77")
    ) %>%
    layout(
      title = paste0("Ranking: ", title),
      xaxis = list(title = title),
      yaxis = list(title = ""),
      margin = list(t = 40),
      font = list(family = "sans-serif", size = 14)
    )
  
}
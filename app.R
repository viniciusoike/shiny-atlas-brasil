library(shiny)
library(bslib)
library(shinycssloaders)

# EKIO brand theme ------------------------------------------------------------
ekio_theme <- bs_theme(
  version = 5,
  bg = "#ffffff",
  fg = "#1A202C",
  primary = "#1E3A5F",
  secondary = "#3A6EA5",
  success = "#2C7A7B",
  warning = "#DD6B20",
  "navbar-bg" = "#1E3A5F",
  base_font = font_collection(
    "Helvetica Neue",
    "Helvetica",
    "Arial",
    "sans-serif"
  ),
  heading_font = font_collection(
    "Helvetica Neue",
    "Helvetica",
    "Arial",
    "sans-serif"
  )
)

ui <- page_navbar(
  title = tags$span(
    "Atlas Brasil",
    style = "font-weight: 600; letter-spacing: 0.03em;"
  ),
  id = "nav",
  theme = ekio_theme,
  header = tags$head(
    includeCSS("styles.css"),
    includeScript("gomap.js")
  ),

  # Interactive Map -------------------------------------------------------------
  nav_panel(
    "Interactive Map",
    fillable = FALSE,
    div(
      class = "outer",
      tmapOutput("map", width = "100%", height = "100%"),
      absolutePanel(
        id = "controls",
        fixed = TRUE,
        draggable = TRUE,
        top = 60,
        left = 75,
        right = "auto",
        bottom = "auto",
        width = 300,
        height = "auto",
        h2("Atlas Brasil"),
        selectInput(
          "resolution",
          "Level of Aggregation",
          c("UDH", "Region"),
          selected = "UDH"
        ),
        selectInput(
          "metro",
          "Metro Region",
          choices = NULL,
          selected = "Baixada Santista"
        ),
        selectInput("year", "Year", choice_years, selected = 2010),
        selectInput(
          "category",
          "Category",
          unique(dict$category),
          selected = "HDI"
        ),
        selectInput(
          "variable",
          "Variable",
          choices = NULL,
          selected = "HDI (overall)"
        ),
        selectInput(
          "maptype",
          "Type of Map",
          names(choice_type),
          selected = "Natural Breaks (Jenks)"
        ),
        numericInput(
          "ngroup",
          "Number of Groups",
          5,
          min = 3,
          max = 10,
          step = 1
        ),
        selectInput(
          "palette",
          "Palette",
          names(choice_pal),
          selected = "EKIO Blue-Orange"
        ),
        h5("Variable Description"),
        htmlOutput("description")
      )
    )
  ),

  # Rank Metro Regions ----------------------------------------------------------
  nav_panel(
    "Rank Metro Regions",
    layout_sidebar(
      sidebar = sidebar(
        width = 300,
        h5("Ranking and Evolution"),
        p(
          class = "text-muted small",
          "Compare variables across Metropolitan Regions.",
          "Census data (2000, 2010) combined with PNAD estimates (2024)."
        ),
        selectInput(
          "cat_plot",
          "Category",
          unique(dict$category),
          selected = "HDI"
        ),
        selectInput(
          "var_plot",
          "Variable",
          choices = NULL,
          selected = "HDI (overall)"
        ),
        hr(),
        h6("Variable Description"),
        htmlOutput("desc_plot")
      ),
      withSpinner(
        plotlyOutput("plot", height = "700px", width = "100%"),
        color = "#1E3A5F"
      )
    )
  ),

  # Download the Data -----------------------------------------------------------
  nav_panel(
    "Download the Data",
    layout_sidebar(
      sidebar = sidebar(
        width = 280,
        h5("Download Data"),
        selectInput(
          "dwn_geo",
          "Aggregation Level",
          choices = c("Metro Region", "Region", "UDH"),
          selected = "Metro Region"
        ),
        checkboxInput("dwn_checkbox", "Include geometry?", value = FALSE),
        downloadButton(
          "dwn_button",
          "Download",
          icon = icon("download"),
          class = "btn-primary w-100 mt-2"
        )
      ),
      card(
        card_header("Data Preview"),
        card_body(
          p(class = "text-muted small", "Preview shows the first 1,000 rows."),
          DT::dataTableOutput("dwn_table", width = "100%")
        )
      )
    )
  ),

  # About -----------------------------------------------------------------------
  nav_panel(
    "About",
    fillable = FALSE,
    layout_columns(
      col_widths = c(-2, 8, -2),
      card(
        card_body(
          class = "p-4",
          h3("Vinicius Oike Reginatto"),
          h5("About Me", class = "text-primary mt-3"),
          p(aboutme_en),
          h5("About this app", class = "text-primary mt-3"),
          p(about_app1),
          p(about_app2),
          p(about_app3),
          h6("Links", class = "mt-4"),
          tags$ul(
            class = "list-unstyled",
            tags$li(tags$a(
              href = "https://github.com/viniciusoike",
              target = "_blank",
              icon("github"),
              " GitHub"
            )),
            tags$li(tags$a(
              href = "https://www.linkedin.com/in/vinicius-oike-993826a9/",
              target = "_blank",
              icon("linkedin"),
              " LinkedIn"
            )),
            tags$li(tags$a(
              href = "https://www.modelodomundo.com",
              target = "_blank",
              icon("globe"),
              " Personal Website"
            ))
          )
        )
      )
    )
  )
)

server <- function(input, output, session) {
  # Interactive Map -------------------------------------------------------------

  category <- reactive({
    dplyr::filter(dict, category == input$category)
  })

  observeEvent(category(), {
    choices <- unique(category()$title_var_en)
    updateSelectInput(inputId = "variable", choices = choices)
  })

  selected_vals <- reactiveValues(
    resolution = "UDH",
    metro = "Baixada Santista"
  )
  res <- reactive({
    input$resolution
  })

  observe({
    req(res(), input$metro)
    selected_vals$resolution <- res()
    selected_vals$metro <- input$metro
  })

  observe({
    metro_choices <- if (res() == "UDH") {
      metro_choice_udh
    } else {
      metro_choice_region
    }
    displayVal <- if (selected_vals$metro %in% metro_choices) {
      selected_vals$metro
    } else {
      NULL
    }
    updateSelectInput(
      session,
      "metro",
      choices = metro_choices,
      selected = displayVal
    )
  })

  city <- reactive({
    req(input$metro)
    input$metro
  })
  variable <- reactive({
    input$variable
  })

  output$description <- renderUI({
    title <- paste0("<b>", variable(), "</b>:")
    description <- subset(dict, title_var_en == variable())$desc_var_en
    htmltools::HTML(paste(title, description))
  })

  output$map <- renderTmap({
    req(input$year, input$maptype, input$palette, input$ngroup)
    map_atlas(
      metro = city(),
      year_sel = input$year,
      geo = res(),
      type = input$maptype,
      pal = input$palette,
      var_sel = variable(),
      n = input$ngroup
    )
  })

  # Rank Plot -------------------------------------------------------------------

  category_rank <- reactive({
    dplyr::filter(dict_rm, category == input$cat_plot)
  })

  observeEvent(category_rank(), {
    choices <- unique(category_rank()$title_var_en)
    updateSelectInput(inputId = "var_plot", choices = choices)
  })

  variable_rank <- reactive({
    input$var_plot
  })

  output$desc_plot <- renderUI({
    title <- paste0("<b>", variable_rank(), "</b>:")
    description <- subset(dict, title_var_en == variable_rank())$desc_var_en
    htmltools::HTML(paste(title, description))
  })

  output$plot <- renderPlotly({
    req(variable_rank())
    plot_rank(variable_rank())
  })

  # Download Data ---------------------------------------------------------------

  sel_geo <- reactive({
    input$dwn_geo
  })

  data <- reactive({
    switch(
      sel_geo(),
      "UDH" = atlas,
      "Region" = atlas_region,
      "Metro Region" = rmdata
    )
  })

  preview <- reactive({
    head(sf::st_drop_geometry(data()), 1000)
  })

  is_geo <- reactive({
    input$dwn_checkbox
  })

  output$dwn_table <- DT::renderDataTable({
    DT::datatable(
      preview(),
      caption = "Preview includes only the first 1,000 rows.",
      extensions = "FixedColumns",
      options = list(scrollX = TRUE, fixedColumns = TRUE, pageLength = 5)
    )
  })

  output$dwn_button <- downloadHandler(
    filename = function() {
      base_name <- tolower(gsub(" ", "_", input$dwn_geo))
      if (is_geo()) paste0(base_name, ".gpkg") else paste0(base_name, ".csv")
    },
    content = function(file) {
      if (is_geo() && sel_geo() != "Metro Region") {
        sf::st_write(data(), file)
      } else {
        vroom::vroom_write(sf::st_drop_geometry(data()), file)
      }
    }
  )
}

shinyApp(ui, server)

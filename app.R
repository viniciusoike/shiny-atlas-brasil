library(shiny)
library(shinycssloaders)

ui <- navbarPage("Atlas Brasil", id = "nav",
        tabPanel(
          "Interactive Map",
          div(class = "outer",
              tags$head(
                includeCSS("styles.css"),
                includeScript("gomap.js")
              ),
              tmapOutput("map", width = "100%", height = "100%"),
              absolutePanel(id = "controls",
                class = "panel panel-default",
                fixed = TRUE,
                draggable = TRUE,
                top = 60,
                left = 75,
                right = "auto",
                bottom = "auto",
                width = 300,
                height = "auto",
                h2("Atlas Brasil"),
                selectInput("resolution", "Level of Aggregation", c("UDH", "Region"), selected = "UDH"),
                selectInput("metro", "Metro Region", choices = NULL, selected = "Baixada Santista"),
                selectInput("year", "Year", choice_years, selected = 2010),
                selectInput("category", "Category", levels(dict$category), selected = "HDI"),
                selectInput("variable", "Variable", choices = NULL, selected = "HDI (overall)"),
                selectInput("maptype", "Type of Map", names(choice_type), selected = "Natural Breaks (Jenks)"),
                numericInput("ngroup", "Number of Groups", 5, min = 3, max = 10, step = 1),
                selectInput("palette", "Palette", names(choice_pal), selected = "Brown-Green"),
                h5("Variable Description"),
                htmlOutput("description")
              )
          )
        ),
        tabPanel("Rank Metro Regions",
          sidebarLayout(
            sidebarPanel(width = 3,
              h3("Ranking and Evolution of Metro Regions"),
              p("This tool allows you to rank and see the evolution of these variables across the Metropolitan Regions. Data is available for only these 20 metro regions."),
              selectInput("cat_plot", htmltools::HTML("<b>Category</b>"), levels(dict$category), selected = "HDI"),
              selectInput("var_plot", htmltools::HTML("<b>Variable</b>"), choices = NULL, selected = "HDI (overall)"),
              h5("Variable Description"),
              htmlOutput("desc_plot")
            ),
            mainPanel(
              plotlyOutput("plot", height = "700px", width = "100%")
            ))
        ),
        tabPanel("Download the Data",
          sidebarLayout(
            sidebarPanel(width = 3,
              h3("Download Data"),
              selectInput("dwn_geo", "Select Aggregation:", choices = c("Metro Region", "Region", "UDH"), selected = "UDH"),
              checkboxInput("dwn_checkbox", "Include geometry?", value = FALSE),
              downloadButton("dwn_button", "Download", icon = icon("download"))
          ),
            mainPanel(width = 9,
              h3("Preview the data"),
              DT::dataTableOutput("dwn_table")))
          ),
        tabPanel("About",
                 fluidRow(
                   column(4,
                          tags$div(
                            class = "container-fluid",
                            tags$h1("Vinicius Oike Reginatto"),
                            tags$h3("About Me"),
                            tags$p(aboutme_en),
                            tags$h3("About this app"),
                            tags$p(about_app),
                            tags$h5("My links:"),
                            tags$ul(
                              tags$li(tags$a(href = "https://twitter.com/viniciusoike", icon("twitter"), "Twitter")),
                              tags$li(tags$a(href = "https://github.com/viniciusoike", icon("github"), "GitHub")),
                              tags$li(tags$a(href = "https://www.linkedin.com/in/vinicius-oike-993826a9/", icon("linkedin"), "LinkedIn")),
                              tags$li(tags$a(href = "https://www.modelodomundo.com", icon("globe"), "Personal Website"))
                            )))
                 ))

)

server <- function(input, output, session) {
  
# Interactive map ---------------------------------------------------------
  
  category <- reactive({
    dplyr::filter(dict, category == input$category)
  })
  
  observeEvent(category(), {
    choices <- unique(category()$title_var_en)
    updateSelectInput(inputId = "variable", choices = choices)
  })
  
  res <- reactive({input$resolution})
  
  observeEvent(res(), {
    if (res() == "UDH") {
      updateSelectInput(inputId = "metro", choices = metro_choice_udh)
    } else {
      updateSelectInput(inputId = "metro", choices = metro_choice_region)
    }
  })
  
  city <- reactive({
    req(input$metro)
    input$metro
  })
  
  variable <- reactive({input$variable})
  
  output$description <- renderUI({
    title <- paste0("<b>", variable(), "</b>:")
    description <- subset(dict, title_var_en == variable())$desc_var_en
    text <- htmltools::HTML(paste(title, description))
    return(text)
  })
  
  output$map <- renderTmap({

    req(input$year)
    req(input$maptype)
    req(input$palette)
    req(input$ngroup)

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
  

# Rank Plot ---------------------------------------------------------------

  category_rank <- reactive({
    dplyr::filter(dict, category == input$cat_plot)
  })
  
  observeEvent(category_rank(), {
    choices <- unique(category_rank()$title_var_en)
    updateSelectInput(inputId = "var_plot", choices = choices)
  })
  
  variable_rank <- reactive({input$var_plot})
  
  output$desc_plot <- renderUI({
    title <- paste0("<b>", variable_rank(), "</b>:")
    description <- subset(dict, title_var_en == variable_rank())$desc_var_en
    text <- htmltools::HTML(paste(title, description))
    return(text)
  })
  
  output$plot <- renderPlotly({
    req(variable_rank())
    plot_rank(variable_rank())
  })
  

# Download Data -----------------------------------------------------------
  
  # Capture aggregation level
  sel_geo <- reactive({input$dwn_geo})
  # Select data based on aggregation
  data <- reactive({
    if (sel_geo() == "UDH") {
      return(atlas)
    } else if (sel_geo() == "Region") {
      return(atlas_region)
    } else {
      return(rmdata)
    }
  })
  # Subset 1000 rows from dataset to preview
  preview <- reactive({
    head(sf::st_drop_geometry(data()), 1000)
  })
  # Capture the checkbox input
  is_geo <- reactive({input$dwn_checkbox})
  
  # Render DataTable with the preview
  output$dwn_table <- DT::renderDataTable({
    DT::datatable(
      preview(),
      caption = "Preview includes only the first 1000 rows.",
      extensions = "FixedColumns",
      options = list(scrollX = TRUE, fixedColumns = TRUE, pageLength = 5))
  })
  
  # Download data
  output$dwn_button <- downloadHandler(
    filename = function() {
      # Convert file name to lower and swap white spaces for underscores
      base_name <- gsub(" ", "_", input$dwn_geo)
      base_name <- tolower(base_name)
      
      if (is_geo()) {
        paste0(base_name, ".gpkg")
      } else {
        paste0(base_name, ".csv")
      }
    },
    # If is TRUE include geometry export .gpkg else export .csv
    content = function(file) {
      # Obs: metro region does not support geometry
      if (is_geo() && sel_geo() != "Metro Region") {
        sf::st_write(data(), file)
      } else {
        vroom::vroom_write(sf::st_drop_geometry(data()), file)
      }
    }
  )
  
}

shinyApp(ui, server)
library(shiny)

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
          left = 20,
          right = "auto",
          bottom = "auto",
          width = 300,
          height = "auto",
          h2("Atlas Brasil"),
          selectInput("metro", "Metro Region", names(choice_metro_regions), selected = "Porto Alegre"),
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
    )
  )

server <- function(input, output, session) {
  
  category <- reactive({
    dplyr::filter(dict, category == input$category)
  })
  
  observeEvent(category(), {
    choices <- unique(category()$title_var_en)
    updateSelectInput(inputId = "variable", choices = choices)
  })
  
  variable <- reactive({input$variable})
  
  output$description <- renderUI({
    title <- paste0("<b>", variable(), "</b>:")
    description <- subset(dict, title_var_en == variable())$desc_var_en
    text <- htmltools::HTML(paste(title, description))
    return(text)
  })
  
  output$map <- renderTmap({
    map_atlas(
      metro = input$metro,
      year_sel = input$year,
      type = input$maptype,
      pal = input$palette,
      var_sel = variable(),
      n = input$ngroup
    )
  })
  

}

shinyApp(ui, server)
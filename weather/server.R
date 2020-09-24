library(shiny)
library(plotly)
library(bigrquery)
library(DBI)

# Define server logic required to draw a histogram
function(input, output) {
  observeEvent(
    input$show_about, {
      showModal(modalDialog("Place descriptive text in this section.", title = 'About'))
    })
  
  # query BigQuery
  rval_bq <- reactive({
    billing <-Sys.getenv("BIGQUERY_TEST_PROJECT")
    token_path <- Sys.getenv("TOKEN_PATH")
    bq_auth(path = "./mpg-data-warehouse-c5cd05731d19.json")
    
    project = "mpg-data-warehouse"
    dataset = "weather_summaries"
    
    con <- dbConnect(
      bigrquery::bigquery(),
      project = project,
      dataset = dataset,
      billing = billing
    )
    
    # weather <- tbl(con, "mpg_ranch_daily")
    sql <- "SELECT * FROM `mpg-data-warehouse.weather_summaries.mpg_ranch_daily`"
    weather_db <- dbGetQuery(con, sql)
    
    # weather_db
    # weather <- dbGetQuery(con, sql)
  })

  initial_load_data <- read_csv('./mpg_weather_daily-200921.csv')
  load_state <- 0  

  rval_data <- reactive({
    if (load_state == 0) {
      initial_load_data %>%
        filter(date_day >= input$date_range[1] &
                 date_day <= input$date_range[2] &
                 station %in% input$station)
    } else {
      rval_bq() %>%
        filter(date_day >= input$date_range[1] &
                 date_day <= input$date_range[2] &
                 station %in% input$station)
    }
  })
  
  output$linePlot_temp <- plotly::renderPlotly(
    rval_data() %>%
      select(date_day, station, temp_F_mean) %>%
      ggplot(aes(x=date_day, y=temp_F_mean)) +
        geom_line(aes(colour = station))
  )
  
  output$linePlot_precip <- plotly::renderPlotly(
    rval_data() %>%
      select(date_day, station, precip_I_mean) %>%
      filter(precip_I_mean > 0) %>%
      ggplot(aes(x=date_day, y=precip_I_mean, color=station)) +
        # geom_point(position="jitter")
        geom_bar(stat="identity")
  )
  
  output$weather_table <- DT::renderDT({
    rval_data() 
      # %>% 
      # filter(station %in% input$station) %>%
      # select(date_day, station, temp_F_mean, temp_F_max, temp_F_min)
    })
  
  output$downloadData <- downloadHandler(
    filename = function() {
      paste('mpg_weather-', input$date_range[1], '_', input$date_range[2], '.csv', sep='')
    },
    content = function(con) {
      write.csv(rval_data(), con)
    }
  )
  
  observeEvent(input$about, {
    url <- "https://docs.google.com/document/d/1WKzE0v4DiwlfKYjMvTEVgzp_-_6jAv4l4CAtqqy-aII/edit?usp=sharing"
    showModal(modalDialog(
      title = "About",
      HTML("Further documentation can be found here: <a href=\"https://docs.google.com/document/d/1WKzE0v4DiwlfKYjMvTEVgzp_-_6jAv4l4CAtqqy-aII/edit?usp=sharing\" target=\"_blank\">Readme Weather Data</a>")
    ))
  })
}
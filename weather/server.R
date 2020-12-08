library(shiny)
library(plotly)
library(bigrquery)
library(DBI)
library(lubridate)

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
  
  # perform Filters
  rval_data <- reactive({
    rval_bq() %>%
      filter(date_day >= input$date_range[1] &
               date_day <= input$date_range[2] &
               station %in% input$station)
    
  })
  
  output$linePlot_temp <- plotly::renderPlotly(
    rval_data() %>%
      select(date_day, station, temp_F_mean) %>%
      ggplot(aes(x=date_day, y=temp_F_mean)) +
        geom_line(aes(colour = station))
  )
  
  output$precip_step <- plotly::renderPlotly(
    rval_data() %>%
      arrange(date_day) %>%
      mutate(year = year(date_day), doy = yday(date_day)) %>%
      group_by(year, station) %>%
      mutate(precip_in = cumsum(precip_in_sum)) %>%
      ungroup() %>%
      ggplot(aes(x = doy, y = precip_in, group = station)) +
      geom_step(aes(color = station), size = 1.0) +
      facet_wrap(vars(year)) +
      labs(x = "day", y = "rainfall (inches)") +
      theme(panel.grid.major.y = element_line(color = "gray90", size = 0.75))
  )
  
  output$weather_table <- DT::renderDT({
    rval_data() 
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
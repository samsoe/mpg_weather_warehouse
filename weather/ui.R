#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(dplyr)
library(ggplot2)

# Define UI for application that draws a histogram
fluidPage(
  
  # Application title
  titlePanel("MPG Ranch Weather"),
  
  # Sidebar with a slider input for number of bins 
  sidebarLayout(
    sidebarPanel(
      dateRangeInput("date_range", 
                     label = "Date range",
                     start = "2019-01-01",
                     end = "2019-12-31"),
      selectInput("station",
                  "Select station:",
                  choices = c("baldy draw", "baldy summit", "indian ridge",
                              "orchard house", "sainfoin bench", "south baldy ridge"),
                  selected = "orchard house",
                  multiple = TRUE),
      downloadButton("downloadData", "Download"),
      actionButton("about", "About")
      # selectInput("variables",
      #             "Select variables:",
      #             choices = c("Temperature", "Precipitation", "Wind"),
      #             selected = "Temperature",
      #             multiple = TRUE),
    ),
    mainPanel(
      tabsetPanel(type = "tabs",
                  tabPanel("Plot", plotlyOutput("linePlot")),
                  tabPanel("Table", DT::DTOutput("weather_table"))
                  # tabPanel("About", textOutput("about"))
      )
    )
  )
)
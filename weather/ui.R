library(shiny)
library(plotly)
# install.packages("shinycssloaders") # comment this out for shinyapps.io
library(shinycssloaders)

# Define UI for application
fluidPage(
  
  # Application title
  titlePanel("MPG Ranch Weather"),
  
  sidebarLayout(
    sidebarPanel(
      dateRangeInput("date_range", 
                     label = "Date range",
                     start = "2019-01-01",
                     end = "2019-12-31",
                     max = Sys.Date() - 1),
      selectInput("station",
                  "Select station:",
                  choices = c("Baldy Draw", "Baldy Summit", "Indian Ridge",
                              "Orchard House", "Sainfoin Bench", "South Baldy Ridge"),
                  selected = "Orchard House",
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
                  tabPanel("Temperature", plotlyOutput("linePlot_temp") %>% withSpinner()),
                  tabPanel("Precipitation", plotlyOutput("linePlot_precip") %>% withSpinner()),
                  tabPanel("Table", DT::DTOutput("weather_table") %>% withSpinner())
      )
    )
  )
)
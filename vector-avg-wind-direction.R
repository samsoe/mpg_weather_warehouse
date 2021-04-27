#' ---
#' title: "Vector averaging degrees of wind direction"
#' author: "Beau Larkin"
#' date: "2021-03-05"
#' output: github_document
#' ---

#' # Description
#' Wind direction is usually reported in degrees, which presents a problem for calculating an average. 
#' For example, if the wind direction for a given period varied between 340 and 20 degrees, 
#' the average direction over that period should be near north (zero degrees), 
#' but taking the arithmetic average of 340 and 20 equals 180, or south. To produce a meaningful average
#' of wind direction, we must use vector functions to decompose degrees into longitudinal and latitudinal 
#' dimensions, calculate the average (and/or a measure of variability), and recombine them to report the 
#' result in degrees. 
#' 
#' Simply calculating the vector average of wind direction fails to take advantage of other 
#' information at our disposal, however.
#' We will also take into account the wind speed, which acts as a weight on direction. For example, if 
#' the wind blows gently from the east for half of a day, and strongly from the north for half of the day,
#' we would expect the average to be closer to north than to east. 
#' 
#' ## Citation
#' This example and script was adapted from 
#' [Grange, S.K. (2014). Technical note : Averaging wind speeds and directions, 1–12](https://www.researchgate.net/publication/262766424_Technical_note_Averaging_wind_speeds_and_directions)
#' 
#' # Load necessary tools
library(knitr)
library(tidyverse)

#' # Create data to motivate example
#' ## Wind directions
#' We will be working with data obtained via API from [Davis Instruments Weatherlink](https://www.davisinstruments.com/weatherlink-cloud/).
#' The API returns wind direction data that are binned into 16 compass directions, and the compass directions are represented 
#' either as text or as an integer in [0, 15]. These integers must be translated into degree equivalents before
#' other calculations can be made. We have confirmed with Davis Instruments that the integer values map to degrees 
#' in the order shown in the following code.   

wind_dir <-
  data.frame(
    wdir_integer = c(0:15),
    wdir_text = c("N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE", "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"),
    wdir_degree = c(22.5 * c(0:15))
  )

#' ### Wind direction data translation
#+ wind_direction_codes
wind_dir %>% kable()

#' ### Example weather data
#' Data used in this example include 1000 rows, split into ten "days" with 100 values for each day.
#' Wind speed is sampled from an integer vector and for this example is unitless. The wind direction
#' data are sampled from the `wind_dir` data frame.

weather_data <-
  data.frame(
    day = rep(1:10, each = 100),
    wind_speed = sample(0:18, size = 1000, replace = TRUE),
    slice_sample(wind_dir, n = 1000, replace = TRUE)
  ) %>%
  glimpse()

#' ### Vector averaging and results
#' New variables are added here to the source data frame. The variables `wdir_u` and `wdir_v` comprise the latitudinal
#' and longitudinal components of the wind direction vector. 
#' 
#' In all summary functions, `na.rm = TRUE` is set because it is almost a given in real weather data that NA
#' or NULL values will be reported. 

## Calculate the u and v wind components, add as new variables in data frame
weather_data$wdir_u <- -weather_data$wind_speed * sin(2 * pi * weather_data$wdir_degree / 360)
weather_data$wdir_v <- -weather_data$wind_speed * cos(2 * pi * weather_data$wdir_degree / 360)
weather_data %>% glimpse()

## Calculate the average of wind vectors, grouped by time (in this case, "day")
weather_summary <-
  weather_data %>%
  group_by(day) %>%
  summarize(
    wind_speed_mean = mean(wind_speed, na.rm = TRUE),
    wdir_u_mean = mean(wdir_u, na.rm = TRUE),
    wdir_v_mean = mean(wdir_v, na.rm = TRUE),
    wdir_deg_avg = (atan2(wdir_u_mean, wdir_v_mean) * 360 / 2 / pi) + 180,
    .groups = "drop"
  )
weather_summary %>% kable()

#' It is possible to calculate the standard deviation of wind speed and wind direction, 
#' but implementing this will take additional work. Applying standard deviations to wind 
#' direction means that the y axis in figures will extend above 360 and below 0, which seems
#' inappropriate. For wind speed, we also will be able to display max and min wind speed, if desired,
#' alleviating the need for a measure of variability. 
#' 
#' #### For information on the standard deviation of wind directions, see:
#' * Wikipedia [page](https://en.wikipedia.org/wiki/Yamartino_method) on the Yamartino method 
#' * *On the Algorithms Used to Compute the Standard Deviation of Wind Direction*, [Farrugia et al. 2009](https://journals.ametsoc.org/view/journals/apme/48/10/2009jamc2050.1.xml)
#' 
#' ### Graphical display
#' This figure is laughably simple with only ten days included, but it's representative 
#' of what wind speed and direction displays often look like. 

#+ Average wind speed
weather_summary %>% 
  ggplot(aes(x = day, y = wind_speed_mean)) +
  geom_line(color = "red") +
  theme_bw()
#+ Average wind direction
weather_summary %>% 
  ggplot(aes(x = day, y = wdir_deg_avg)) +
  geom_line(color = "blue") +
  theme_bw()

#' ### Proof of concept
#' Let's make sure that this works with wind directions that should average to north.
dir_vec <- c(310, 340, 355, 5, 15, 20)
sp_vec = sample(2:7)
u <- -sp_vec * sin(2 * pi * dir_vec / 360)
v <- -sp_vec * cos(2 * pi * dir_vec / 360)

#' The result should be close to 360 and not close to the average of `dir_vec`
## Result of vector averaging:
(atan2(mean(u), mean(v)) * 360 / 2 / pi) + 180
## Arithmetic mean of vector:
mean(dir_vec)


#' ### Code simplification
#' The code here could easily be streamlined into a unified block, but for implementation of this
#' in our weather application, this script must be adapted to SQL, so for now it's best to leave it like
#' it is. 
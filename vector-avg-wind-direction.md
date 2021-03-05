Vector averaging degrees of wind direction
================
Beau Larkin
2021-03-05

# Description

Wind direction is usually reported in degrees, which presents a problem
for calculating averages. If the wind direction for a give time period
varied bewteen 340 and 20 degrees, the average direction near north, but
taking the average of 340 and 20 equals 180, or south. To produce a
meaningful average of wind direction, we must use vector functions to
decompose degrees into longitudinal and latitudinal dimensions,
calculate the average (and/or a measure of variability), and recombine
them to report the result in degrees.

Simply calculating the vector average of wind direction will result in
an incomplete average, however. We will also take into account the wind
speed, which acts as a weight on direction. For example, if the wind
blows gently from the east for half of a day, and strongly from the
north for half of the day, we would expect the average to be closer to
north than to east.

## Citation

This example and script was adapted from [Grange, S.K. (2014). Technical
note : Averaging wind speeds and directions,
1–12](https://www.researchgate.net/publication/262766424_Technical_note_Averaging_wind_speeds_and_directions)

# Load necessary tools

``` r
library(knitr)
library(tidyverse)
```

    ## ── Attaching packages ──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────── tidyverse 1.3.0 ──

    ## ✓ ggplot2 3.3.2     ✓ purrr   0.3.4
    ## ✓ tibble  3.0.3     ✓ dplyr   1.0.1
    ## ✓ tidyr   1.1.1     ✓ stringr 1.4.0
    ## ✓ readr   1.3.1     ✓ forcats 0.5.0

    ## ── Conflicts ─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────── tidyverse_conflicts() ──
    ## x dplyr::filter() masks stats::filter()
    ## x dplyr::lag()    masks stats::lag()

# Create data to motivate example

## Wind directions

We will be working with data obtained via API from [Davis Instruments
Weatherlink](https://www.davisinstruments.com/weatherlink-cloud/). Our
API returns wind direction data that are binned into 16 compass
directions, and the compass directions are represented either as text or
as an integer in c(0, 15). Translating these stored variables into
degrees will require translation. Note: we need to find out whether the
mapping used by Davis follows the following schema before implementing
this script with real data.

``` r
wind_dir <-
  data.frame(
    wdir_integer = c(0:15),
    wdir_text = c("N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE", "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"),
    wdir_degree = c(22.5 * c(0:15))
  )
```

### Wind direction data translation

``` r
wind_dir %>% kable()
```

| wdir\_integer | wdir\_text | wdir\_degree |
|--------------:|:-----------|-------------:|
|             0 | N          |          0.0 |
|             1 | NNE        |         22.5 |
|             2 | NE         |         45.0 |
|             3 | ENE        |         67.5 |
|             4 | E          |         90.0 |
|             5 | ESE        |        112.5 |
|             6 | SE         |        135.0 |
|             7 | SSE        |        157.5 |
|             8 | S          |        180.0 |
|             9 | SSW        |        202.5 |
|            10 | SW         |        225.0 |
|            11 | WSW        |        247.5 |
|            12 | W          |        270.0 |
|            13 | WNW        |        292.5 |
|            14 | NW         |        315.0 |
|            15 | NNW        |        337.5 |

### Example weather data

Data used in this example includes 1000 rows, split into ten “days” with
100 values for each day. Wind speed is sampled from an integer vector
and for this example is unitless. The wind direction data are sampled
from the `wind_dir` data frame.

``` r
weather_data <-
  data.frame(
    day = rep(1:10, each = 100),
    wind_speed = sample(0:18, size = 1000, replace = TRUE),
    slice_sample(wind_dir, n = 1000, replace = TRUE)
  ) %>%
  glimpse()
```

    ## Rows: 1,000
    ## Columns: 5
    ## $ day          <int> 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,…
    ## $ wind_speed   <int> 11, 0, 15, 4, 14, 18, 11, 2, 17, 16, 4, 3, 2, 1, 2, 15, …
    ## $ wdir_integer <int> 2, 10, 3, 11, 8, 4, 10, 12, 2, 0, 0, 14, 3, 14, 8, 14, 0…
    ## $ wdir_text    <chr> "NE", "SW", "ENE", "WSW", "S", "E", "SW", "W", "NE", "N"…
    ## $ wdir_degree  <dbl> 45.0, 225.0, 67.5, 247.5, 180.0, 90.0, 225.0, 270.0, 45.…

### Vector averaging and results

New variables are added here to the source data frame. The variables
`wdir_u` and `wdir_v` comprise the latitudinal and longitudinal
components of the wind direction vector.

In all summary functions, `na.rm = TRUE` is set because it is almost a
given in real weather data that NA or NULL values will be reported.

``` r
## Calculate the u and v wind components, add as new variables in data frame
weather_data$wdir_u <- -weather_data$wind_speed * sin(2 * pi * weather_data$wdir_degree / 360)
weather_data$wdir_v <- -weather_data$wind_speed * cos(2 * pi * weather_data$wdir_degree / 360)
weather_data %>% glimpse()
```

    ## Rows: 1,000
    ## Columns: 7
    ## $ day          <int> 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,…
    ## $ wind_speed   <int> 11, 0, 15, 4, 14, 18, 11, 2, 17, 16, 4, 3, 2, 1, 2, 15, …
    ## $ wdir_integer <int> 2, 10, 3, 11, 8, 4, 10, 12, 2, 0, 0, 14, 3, 14, 8, 14, 0…
    ## $ wdir_text    <chr> "NE", "SW", "ENE", "WSW", "S", "E", "SW", "W", "NE", "N"…
    ## $ wdir_degree  <dbl> 45.0, 225.0, 67.5, 247.5, 180.0, 90.0, 225.0, 270.0, 45.…
    ## $ wdir_u       <dbl> -7.778175e+00, 0.000000e+00, -1.385819e+01, 3.695518e+00…
    ## $ wdir_v       <dbl> -7.778175e+00, 0.000000e+00, -5.740251e+00, 1.530734e+00…

``` r
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
```

| day | wind\_speed\_mean | wdir\_u\_mean | wdir\_v\_mean | wdir\_deg\_avg |
|----:|------------------:|--------------:|--------------:|---------------:|
|   1 |              8.87 |     0.4376291 |     0.6945182 |     212.215806 |
|   2 |              8.93 |     0.0263180 |    -1.2107463 |     358.754758 |
|   3 |              9.14 |     0.0900736 |    -0.7247804 |     352.915769 |
|   4 |              8.30 |    -0.1156860 |     0.8972537 |     172.653188 |
|   5 |              9.10 |     0.1523622 |    -0.3249424 |     334.878600 |
|   6 |              8.99 |     0.6301786 |    -0.4700278 |     306.717944 |
|   7 |              9.57 |     0.0521741 |    -0.0117936 |     282.737307 |
|   8 |              9.25 |     0.5144167 |    -0.5243476 |     315.547747 |
|   9 |              8.28 |    -0.9037908 |     0.3555387 |     111.473982 |
|  10 |              8.58 |    -0.1018081 |    -0.6174415 |       9.363084 |

It is possible to calculate the standard deviation of wind speed and
wind direction, but implementing this will take additional work.
Applying standard deviations to wind direction mean that the y axis in
figures will extend above 360 and below 0, which seems inappropriate.
For wind speed, we also will be able to display max and min wind speed,
if desired, alleviating the need for a measure of variability.

#### For information on the standard deviation of wind directions, see:

-   Wikipedia [page](https://en.wikipedia.org/wiki/Yamartino_method) on
    the Yamartino method
-   *On the Algorithms Used to Compute the Standard Deviation of Wind
    Direction*, [Farrugia et
    al. 2009](https://journals.ametsoc.org/view/journals/apme/48/10/2009jamc2050.1.xml)

### Graphical display

This figure is laughably simple with only ten days included, but it’s
representative of what wind speed and direction displays often look
like.

``` r
weather_summary %>% 
  ggplot(aes(x = day, y = wind_speed_mean)) +
  geom_line(color = "red") +
  theme_bw()
```

![](vector-avg-wind-direction_files/figure-gfm/Average%20wind%20speed-1.png)<!-- -->

``` r
weather_summary %>% 
  ggplot(aes(x = day, y = wdir_deg_avg)) +
  geom_line(color = "blue") +
  theme_bw()
```

![](vector-avg-wind-direction_files/figure-gfm/Average%20wind%20direction-1.png)<!-- -->

### Proof of concept

Let’s make sure that this works with wind directions that should average
to north.

``` r
dir_vec <- c(310, 340, 355, 5, 15, 20)
sp_vec = sample(2:7)
u <- -sp_vec * sin(2 * pi * dir_vec / 360)
v <- -sp_vec * cos(2 * pi * dir_vec / 360)
## Should be close to 360 and not close to the average of `dir_vec`
mean(dir_vec)
```

    ## [1] 174.1667

``` r
(atan2(mean(u), mean(v)) * 360 / 2 / pi) + 180
```

    ## [1] 354.6107

### Code simplification

The code here could easily be streamlined into a unified block, but for
implementation of this in our weather application, this script must be
adapted to SQL, so for now it’s best to leave it like it is.

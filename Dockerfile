FROM openanalytics/r-shiny

MAINTAINER Erik Samsoe "esamsoe@gmail.com"
 
# install R package dependencies
RUN apt-get update && apt-get -qq -y install curl \
    libssl-dev \
    libcurl4-openssl-dev \
    ## clean up
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/ \
    && rm -rf /tmp/downloaded_packages/ /tmp/*.rds
   
RUN apt-get update && apt-get install -y \
    sudo \
    pandoc \
    pandoc-citeproc \
    libcurl4-gnutls-dev \
    libcairo2-dev \
    libxt-dev \
    libssh2-1-dev


# install needed R packages
RUN R -e "install.packages(c('plotly', 'tidyverse', 'flexdashboard', 'knitr', 'shiny', 'lubridate', 'readr', 'DT', 'leaflet'), dependencies = TRUE, repos='http://cran.rstudio.com/')"

## Install packages from CRAN
RUN install2.r --error \
    -r 'http://cran.rstudio.com' \
    googleAuthR \
    ## install Github packages
    ## clean up
    && rm -rf /tmp/downloaded_packages/ /tmp/*.rds


# Make directory and copy Rmarkdown flexdashboard file in it
RUN mkdir -p /bin
COPY weather.Rmd /bin/weather.Rmd
COPY mpg_weather-2013_2020.csv /bin/mpg_weather-2013_2020.csv
COPY weather_station_location.csv /bin/weather_station_location.csv
COPY shiny-customized.config /bin/shiny-customized.config


# Make all app files readable (solves issue when dev in Windows, but building in Ubuntu)
RUN chmod -R 755 /bin

# Expose port on Docker container
EXPOSE 3838

# Run flexdashboard as localhost and on exposed port in Docker container
CMD ["R", "-e", "rmarkdown::run('/bin/weather.Rmd', shiny_args = list(port = 3838, host = '0.0.0.0'))"]

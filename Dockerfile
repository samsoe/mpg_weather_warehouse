FROM rocker/shiny

MAINTAINER esamsoe@gmail.com
 
# Install dependency libraries
RUN apt-get update && apt-get install -y  \
            libxml2-dev \
            libudunits2-dev \
            libssh2-1-dev \
            libcurl4-openssl-dev \
            libsasl2-dev \
	          libv8-dev \
            && rm -rf /var/lib/apt/lists/*
	

# install needed R packages
RUN    R -e "install.packages(c('DT', 'readr', 'lubridate', 'tidyverse', 'flexdashboard', 'knitr', 'plotly', 'shiny', 'leaflet'), 
                              dependencies = TRUE, repo='http://cran.r-project.org')"

# make directory and copy Rmarkdown flexdashboard file in it
RUN mkdir -p /bin
COPY weather.Rmd  /bin/weather.Rmd
COPY shiny-customized.config  /usr/bin/shiny-server.conf

# make all app files readable (solves issue when dev in Windows, but building in Ubuntu)
RUN chmod -R 755 /bin

# expose port on Docker container
EXPOSE 3838

# run flexdashboard as localhost and on exposed port in Docker container
CMD ["R", "-e", "rmarkdown::run('/bin/weather.Rmd', shiny_args = list(port = 3838, host = '0.0.0.0'))"]
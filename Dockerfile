FROM rocker/r-ver:4.5.3

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        libgdal-dev \
        libgeos-dev \
        libproj-dev \
        libudunits2-dev \
        libcurl4-openssl-dev \
        libssl-dev \
        libxml2-dev \
    && rm -rf /var/lib/apt/lists/*

RUN Rscript -e 'install.packages(c("dplyr", "leaflet", "readr", "readxl", "sf", "shiny", "stringr", "tidyr"))'

WORKDIR /app
COPY . /app

EXPOSE 10000

CMD ["R", "-e", "shiny::runApp('.', host='0.0.0.0', port=as.integer(Sys.getenv('PORT', '10000')), launch.browser=FALSE)"]

# Atlas Brasil Explorer

> Interactive Shiny dashboard for exploring human development indicators across Brazilian metropolitan regions.

[![Live App](https://img.shields.io/badge/Live%20App-Posit%20Connect-blue)](https://viniciusoike-shiny-atlas-brasil.share.connect.posit.cloud)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

## Overview

This dashboard visualizes data from [Atlas Brasil](http://www.atlasbrasil.org.br/), a Brazilian research initiative that maps human development at the sub-municipal level. The app covers **25 metropolitan regions** and provides indicators for **2000 and 2010**, organized into categories including HDI, income, education, housing, and vulnerability.

Key features:

- **Interactive choropleth map** — explore indicators at the UDH (Human Development Unit) or metropolitan region level, with customizable classification methods and color palettes
- **Metro region rankings** — dumbbell chart comparing all metro regions across two census years for any selected indicator
- **Data download** — export the full dataset (with or without geometry) in your preferred aggregation level

## Live Demo

Access the app at: **https://viniciusoike-shiny-atlas-brasil.share.connect.posit.cloud**

## Tech Stack

| Tool | Purpose |
|------|---------|
| [Shiny](https://shiny.posit.co/) | Web application framework |
| [tmap](https://r-tmap.github.io/tmap/) | Interactive choropleth maps |
| [plotly](https://plotly.com/r/) | Dumbbell / ranking chart |
| [readr](https://readr.tidyverse.org/) | Fast serialization of spatial data |
| [renv](https://rstudio.github.io/renv/) | Reproducible dependency management |

## Repository Structure

```
.
├── app.R              # Main Shiny app (UI + server)
├── R/
│   ├── _setup.R       # Data loading and UI choices
│   ├── map_fun.R      # tmap rendering helpers
│   ├── plot_fun.R     # plotly chart helpers
│   └── utils.R        # Shared utilities
├── data/              # Cleaned data (rds + csv)
├── data-raw/          # Raw Atlas Brasil files + cleaning scripts
├── styles.css         # Custom CSS
└── gomap.js           # JavaScript for map interaction
```

Raw data is downloaded from the [Atlas Brasil library](http://www.atlasbrasil.org.br/acervo/biblioteca) and cleaned in `data-raw/`. Spatial objects are stored as `.rds` files; translated variable dictionaries (`dictionary_*.xlsx`) are also included there.

## Related Dashboards

| Dashboard | Description |
|-----------|-------------|
| [shiny-firjan-ifdm](https://github.com/viniciusoike/shiny-firjan-ifdm) | FIRJAN Municipal Development Index (IFDM) across all 5,570 Brazilian municipalities (2013–2023) |
| [shiny-painel-mercado](https://github.com/viniciusoike/shiny-painel-mercado) | Brazilian real estate market indices: prices, credit, macro, and São Paulo housing indicators |
| [metrosp-explorer](https://github.com/viniciusoike/metrosp-explorer) | Passenger demand on the São Paulo metro, built with Shiny + bslib |

## Data Source

Atlas Brasil is produced by the [PNUD Brasil](https://www.undp.org/pt/brazil), [Ipea](https://www.ipea.gov.br/), and [FJP](https://fjp.mg.gov.br/). The underlying methodology follows the UN Human Development Index framework applied at sub-municipal geographies.

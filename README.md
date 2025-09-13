# Atlas Brasil Explorer

This is a repository for the Atlas Brasil Shiny Dashboard. You can access the interactive app [here](https://viniciusoike.shinyapps.io/shiny-atlas-brasil/).

### Repository Structure

This repository is organized and structured similarly to an R package, although it is not a package itself. I do so to keep the workflow efficient. The raw, uncleaned data from Atlas Brasil, downloaded from their [site](http://www.atlasbrasil.org.br/acervo/biblioteca), is inside the `/data-raw` folder. This folder also contains the R scripts used to clean the data. The original files and dictionaries are compressed in zip format. Additionally, I created the Excel sheets named `dictionary_*` since I had to translate all variable names and descriptions.

The cleaned data is exported to the `/data` folder. Tables are exported to `csv` and the `sf` objects (shapefiles with data) are exported to `qs` for both size and efficiency reasons[^readme-1].

[^readme-1]: I did experiment with `gpkg` and `rds` with different types of compression as well and found the `qs` extension to work better. For more information on reading and writting `qs` files check the [qs repository](https://github.com/traversc/qs).

The actual scripts used inside the app reside in the `/R` folder. The interactive map is made with `tmap` and the dumbbell plot is made with `plotly`. Data manipulation inside the app is minimal. The overall user interface (UI) and JavaScript code for the map was heavily inspired by the [SuperZip example from the Shiny Gallery](https://github.com/rstudio/shiny-examples/tree/main/063-superzip-example).

To ensure future compatibility, I utilize the `renv` [package](https://rstudio.github.io/renv/articles/renv.html#dependency-discovery), which helps maintain the functionality of the app even if the packages used undergo changes.
# GeoDensityR

GeoDensityR is an R package for generating density rasters from polygon shapefiles and tabular census or survey data.

The package:
- joins polygon and tabular datasets
- calculates density values
- rasterizes polygon densities
- exports ASCII or GeoTIFF rasters

Useful for:
- epidemiology
- ecology
- livestock distribution
- population density
- spatial analysis
- disease modeling

## Installation

```r
devtools::install_github("sahalpaladan/GeoDensityR")
```
## Usage
library(GeoDensityR)

generate_density_raster(
    csv_file = "Livestock_census_GJ_RJ.csv",
    
    shp_file = "GJ_RJ_District_Shape_File.shp",
    
    join_shp = "District",
    
    join_csv = "District",
    
    value_col = "Cattle",
    
    resolution = 0.1,
    
    output = "density.asc"
    
)
## Note
Inside Livestock_census_GJ_RJ.csv file have demo values only.
## Online Shiny App

Access the online GeoDensityR Shiny application:

https://sahalpaladan.shinyapps.io/geodensityr_shiny/

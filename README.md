# GeoDensityR <img src="man/figures/logo.png" align="right" height="139" alt="" />

<!-- badges: start -->
[![CRAN status](https://www.r-pkg.org/badges/version/GeoDensityR)](https://CRAN.R-project.org/package=GeoDensityR)
<!-- badges: end -->

Census and survey counts are usually published per administrative unit (districts, states, tracts), while environmental data come as regular raster grids. **GeoDensityR** joins a table of counts to a polygon layer, divides each count by the polygon's area on the ellipsoid, and writes the resulting density onto a raster of the resolution you choose. The result is a `terra` `SpatRaster` that can be stacked with climate or land-cover layers.

---

From CRAN:

* **Flexible Multi-Routing Inputs:** Natively processes both in-memory R spatial objects (`terra::SpatVector`, `sf::sf`), relational data frames, or physical disk file paths (`.shp`, `.csv`).
* **Geodesic Spatial Precision:** Employs ellipsoidal surface calculation models (`terra::expanse()`) to evaluate precise spatial polygon areas everywhere on Earth without projection distortion.
* **Unified Pipeline:** Automates string-cleaning lookups, tabular joins, variable area density normalizations, and high-performance C++ rasterization in a single function call.
* **Standardized GIS Exports:** Decoupled file I/O allows direct saving to standard `.tif` (GeoTIFF) or `.asc` (Esri ASCII Grid) matrix structures.

---

## 🛠️ Installation

You can install the stable release version of **GeoDensityR** directly from CRAN:

```R
install.packages("GeoDensityR")
```

Development version from GitHub:

```r
# install.packages("remotes")
remotes::install_github("sahalpaladan/GeoDensityR")
```

## Example

```r
library(GeoDensityR)
library(terra)

# Four districts as polygons, and a table of populations
districts <- terra::vect(
  c("POLYGON((0 0, 2 0, 2 2, 0 2, 0 0))",
    "POLYGON((2 0, 4 0, 4 2, 2 2, 2 0))",
    "POLYGON((0 2, 4 2, 4 3, 0 3, 0 2))",
    "POLYGON((0 3, 4 3, 4 4, 0 4, 0 3))"),
  crs = "EPSG:4326"
)
districts$district_id <- c("D1", "D2", "D3", "D4")

census <- data.frame(
  ID         = c("D1", "D2", "D3", "D4"),
  population = c(120000, 45000, 300000, 80000)
)

dens <- generate_density_raster(
  spatial_target  = districts,
  attribute_table = census,
  join_spatial    = "district_id",
  join_attribute  = "ID",
  value_col       = "population",
  resolution      = 0.1
)

terra::plot(dens, main = "People per square kilometre")
```

`spatial_target` can be a `terra::SpatVector`, an `sf` object or a path to a shapefile, and `attribute_table` can be a data frame or a path to a CSV file. Use `output = "density.tif"` to write the result to disk.

## Things to know

* **Resolution units.** `resolution` is in the units of the layer's coordinate reference system. For degrees, reproject first: `v <- terra::project(terra::vect("boundaries.shp"), "EPSG:4326")`. Areas are always computed on the ellipsoid.
* **Numbers stored as text.** A CSV with values such as `"36,438"` is read as text. Remove the separators first: `tab$count <- as.numeric(gsub(",", "", tab$count))`.
* **Keys.** Keys are matched without regard to case or surrounding spaces. Polygons that share a key (for example a state made of separate islands) share the value in proportion to their area. Polygons with no matching row receive `NA` and a warning.
* **Totals.** Each cell takes the density of the polygon containing its centre, so density times cell area summed over the raster can differ slightly from the original total. In a test with a national livestock census at 0.05 degrees, the difference was about 0.03% to 0.06%.
* **Uniform density within polygons.** The method does not redistribute counts within a unit. For that, use areal-interpolation or dasymetric methods.

See `vignette("GeoDensityR")` for a longer walk-through.

## Citation

Paladan S, Chanda MM (2026). *GeoDensityR: Generate Density Rasters from Polygon and Census Data*. R package version 0.2.1. <https://doi.org/10.32614/CRAN.package.GeoDensityR>

## Contributing

Bug reports and pull requests are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

MIT

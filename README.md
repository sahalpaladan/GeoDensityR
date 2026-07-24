# GeoDensityR <img src="man/figures/logo.png" align="right" height="139" alt="" />

<!-- badges: start -->
[![CRAN status](https://r-pkg.org)](https://r-project.org)
[![CRAN RStudio mirror downloads](https://r-pkg.org)](https://r-project.org)
[![License: MIT](https://shields.io)](https://opensource.org)
<!-- badges: end -->

**GeoDensityR** provides an optimized, open-source programmatic framework for the R environment to automate the integration, normalization, and surface rasterization of tabular attributes over complex vector geometries.

The package reconciles discrete, boundary-constrained census or survey counts with uniform grids, calculating globally precise density allocations directly on ellipsoidal surfaces without relying on distortive local projection coordinates.

---

## 🚀 Key Features

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

Alternatively, you can install the development version from GitHub using `remotes`:

```R
# install.packages("remotes")
remotes::install_github("sahalpaladan/GeoDensityR")
```

---

## 📖 Quick Start Usage Walkthrough

This reproducible example demonstrates how to process demographic data using in-memory spatial layers:

```R
library("GeoDensityR")
library("terra")

# 1. Create a dummy spatial layer with 2 zones (WGS84)
wkt_polys <- c(
  "POLYGON ((77.5 12.5, 77.6 12.5, 77.6 12.6, 77.5 12.6, 77.5 12.5))",
  "POLYGON ((77.6 12.5, 77.7 12.5, 77.7 12.6, 77.6 12.6, 77.6 12.5))"
)
spatial_zones <- terra::vect(wkt_polys, crs = "EPSG:4326")
spatial_zones$Zone_Code <- c("Region_A", "Region_B")

# 2. Build a matching census table data frame
census_table <- data.frame(
  ID = c("Region_A", "Region_B"),
  Population = c(55000, 112000),
  stringsAsFactors = FALSE
)

# 3. Generate the continuous density surface matrix
density_surface <- generate_density_raster(
  spatial_target   = spatial_zones,     # Memory SpatVector
  attribute_table  = census_table,      # Memory data.frame
  join_spatial     = "Zone_Code",
  join_attribute   = "ID",
  value_col        = "Population",
  resolution       = 0.005,             # Pixel grid spacing config
  output           = "population_density.tif" # Optional auto-write to disk
)

# 4. Visualize the generated surface output
plot(density_surface, main = "Ellipsoidal Density Surface (People / km²)")
plot(spatial_zones, add = TRUE, border = "white", lwd = 1.5)
```

---

## 📜 Academic Citation

If you use `GeoDensityR` in your research or academic publications, please cite the software package as follows:

```text
Paladan S (2026). GeoDensityR: An Algorithmic Framework for Generating Continuous 
Density Rasters from Disparate Polygon and Tabular Data Assemblies. 
R package version 0.2.0, URL: https://r-project.org.
```

---

## 🤝 Contributing & Bug Reports

Contributions, feature requests, and code enhancements are welcome! If you encounter any unexpected performance issues, edge-case structural bugs, or parsing validation errors, please file an issue with a reproducible workflow example on the [GitHub Issues Tracker](https://github.com).

**License:** Developed under the open-source [MIT License](LICENSE).

# GeoDensityR 0.2.2

* Polygons sharing a key now share the value in proportion to their area; previously each received the full value.
* Warnings for polygons with no table row, table rows with no polygon, non-numeric values, and layers not in longitude/latitude.
* Duplicated keys in the attribute table are now an error.
* Documentation clarifies that `resolution` is in CRS units and that each cell takes the value of the polygon containing its centre.
* Added a vignette and unit tests for the key matching, warnings and CRS checks.

# GeoDensityR 0.2.0

* Refactored `generate_density_raster()` to process in-memory objects (`SpatVector`, `sf`, `data.frame`) alongside structural file paths.
* Removed hardcoded coordinate projection references (`EPSG:32643`). The engine now calculates globally precise ellipsoidal spatial areas natively using `terra::expanse()`.
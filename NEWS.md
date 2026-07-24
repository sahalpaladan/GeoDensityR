# GeoDensityR 0.2.0

* Refactored `generate_density_raster()` to process in-memory objects (`SpatVector`, `sf`, `data.frame`) alongside structural file paths.
* Removed hardcoded coordinate projection references (`EPSG:32643`). The engine now calculates globally precise ellipsoidal spatial areas natively using `terra::expanse()`.

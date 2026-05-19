#' Generate Density Raster from Polygon and Census Data
#'
#' @export

generate_density_raster <- function(
  csv_file,
  shp_file,
  join_shp,
  join_csv,
  value_col,
  resolution = 0.1,
  output = "density.asc"
) {

  library(terra)

  # ---------------------------------
  # CHECK FILES
  # ---------------------------------
  if (!file.exists(csv_file)) {
    stop("CSV file not found")
  }

  if (!file.exists(shp_file)) {
    stop("Shapefile not found")
  }

  # ---------------------------------
  # READ DATA
  # ---------------------------------
  census_data <- read.csv(
    csv_file,
    stringsAsFactors = FALSE
  )

  polygons <- terra::vect(shp_file)

  # ---------------------------------
  # CHECK COLUMNS
  # ---------------------------------
  if (!(join_shp %in% names(polygons))) {
    stop(
      paste(
        "Join column not found in shapefile:",
        join_shp
      )
    )
  }

  if (!(join_csv %in% names(census_data))) {
    stop(
      paste(
        "Join column not found in CSV:",
        join_csv
      )
    )
  }

  if (!(value_col %in% names(census_data))) {
    stop(
      paste(
        "Value column not found in CSV:",
        value_col
      )
    )
  }

  # ---------------------------------
  # EXTRACT CHARACTER VECTORS
  # ---------------------------------
  shp_names <- as.character(
    terra::values(polygons)[[join_shp]]
  )

  csv_names <- as.character(
    census_data[[join_csv]]
  )

  # ---------------------------------
  # CLEAN NAMES
  # ---------------------------------
  shp_names <- toupper(trimws(shp_names))

  csv_names <- toupper(trimws(csv_names))

  # ---------------------------------
  # MATCH VALUES
  # ---------------------------------
  matched_values <- census_data[[value_col]][
    match(shp_names, csv_names)
  ]

  matched_values <- as.numeric(matched_values)

  # ---------------------------------
  # ADD VALUES TO SPATVECTOR
  # ---------------------------------
  polygons$joined_value <- matched_values

  # ---------------------------------
  # MATCH REPORT
  # ---------------------------------
  matched_count <- sum(
    !is.na(matched_values)
  )

  total_polygons <- length(shp_names)

  message(
    paste(
      "Matched",
      matched_count,
      "out of",
      total_polygons,
      "polygons"
    )
  )

  # ---------------------------------
  # SHOW UNMATCHED NAMES
  # ---------------------------------
  unmatched <- shp_names[
    is.na(matched_values)
  ]

  if (length(unmatched) > 0) {

    message("Unmatched districts:")

    print(unique(unmatched))
  }

  # ---------------------------------
  # PROJECT TO UTM
  # ---------------------------------
  polygons_utm <- terra::project(
    polygons,
    "EPSG:32643"
  )

  # ---------------------------------
  # AREA CALCULATION
  # ---------------------------------
  polygons_utm$area_km2 <-
    terra::expanse(
      polygons_utm,
      unit = "km"
    )

  # ---------------------------------
  # DENSITY
  # ---------------------------------
  polygons_utm$density <-
    polygons_utm$joined_value /
    polygons_utm$area_km2

  # ---------------------------------
  # BACK TO WGS84
  # ---------------------------------
  polygons_final <- terra::project(
    polygons_utm,
    "EPSG:4326"
  )

  # ---------------------------------
  # CREATE TEMPLATE
  # ---------------------------------
  r_template <- terra::rast(
    polygons_final,
    resolution = resolution
  )

  # ---------------------------------
  # RASTERIZE
  # ---------------------------------
  density_raster <- terra::rasterize(
    polygons_final,
    r_template,
    field = "density"
  )

  # ---------------------------------
  # SAVE OUTPUT
  # ---------------------------------
  if (grepl("\\.tif$", output)) {

    terra::writeRaster(
      density_raster,
      output,
      filetype = "GTiff",
      overwrite = TRUE
    )

  } else {

    terra::writeRaster(
      density_raster,
      output,
      filetype = "AAIGrid",
      overwrite = TRUE
    )
  }

  # ---------------------------------
  # SUCCESS MESSAGE
  # ---------------------------------
  message(
    paste(
      "Density raster created:",
      output
    )
  )

  return(density_raster)
}
#' Generate Density Raster from Polygon and Tabular Data
#'
#' Creates a density raster by joining polygon attributes with
#' tabular data and calculating density as:
#' value / polygon area.
#'
#' @param csv_file Path to CSV file.
#' @param shp_file Path to polygon shapefile (.shp).
#' @param join_shp Join column in shapefile.
#' @param join_csv Join column in CSV.
#' @param value_col Numeric column used for density calculation.
#' @param resolution Output raster resolution.
#' @param output Output raster filename (.asc or .tif).
#'
#' @return A terra SpatRaster object.
#'
#' @examples
#' if (file.exists("population.csv") &&
#'     file.exists("districts.shp")) {
#'   generate_density_raster(
#'     csv_file = "population.csv",
#'     shp_file = "districts.shp",
#'     join_shp = "District",
#'     join_csv = "District",
#'     value_col = "Population",
#'     resolution = 0.1,
#'     output = "density.asc"
#'   )
#' }
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

    if (!file.exists(csv_file)) {
        stop("CSV file does not exist.")
    }

    if (!file.exists(shp_file)) {
        stop("Shapefile does not exist.")
    }

    census_data <- utils::read.csv(
        csv_file,
        stringsAsFactors = FALSE
    )

    polygons <- terra::vect(shp_file)

    if (!(join_shp %in% names(polygons))) {
        stop("Join column not found in shapefile.")
    }

    if (!(join_csv %in% names(census_data))) {
        stop("Join column not found in CSV.")
    }

    if (!(value_col %in% names(census_data))) {
        stop("Value column not found in CSV.")
    }

    shp_names <- toupper(
        trimws(
            as.character(
                terra::values(polygons)[[join_shp]]
            )
        )
    )

    csv_names <- toupper(
        trimws(
            as.character(
                census_data[[join_csv]]
            )
        )
    )

    matched_values <- census_data[[value_col]][
        match(shp_names, csv_names)
    ]

    polygons$joined_value <- as.numeric(matched_values)

    matched_count <- sum(!is.na(polygons$joined_value))

    message(
        paste(
            "Matched",
            matched_count,
            "out of",
            length(shp_names),
            "polygons"
        )
    )

    polygons_utm <- terra::project(
        polygons,
        "EPSG:32643"
    )

    polygons_utm$area_km2 <- terra::expanse(
        polygons_utm,
        unit = "km"
    )

    polygons_utm$density <-
        polygons_utm$joined_value /
        polygons_utm$area_km2

    polygons_final <- terra::project(
        polygons_utm,
        "EPSG:4326"
    )

    template <- terra::rast(
        polygons_final,
        resolution = resolution
    )

    density_raster <- terra::rasterize(
        polygons_final,
        template,
        field = "density"
    )

    if (grepl("\\.tif$", output, ignore.case = TRUE)) {

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

    message(
        paste(
            "Density raster created:",
            output
        )
    )

    return(density_raster)
}
#' Generate Density Raster from Polygon and Tabular Data
#'
#' Creates a continuous density raster surface by joining vector spatial
#' layers with tabular data frameworks, normalizing values by ellipsoidal
#' polygon area calculations.
#'
#' @details
#' Keys are matched without regard to case or surrounding whitespace. If
#' several polygons share a key (for example a state made of separate islands),
#' the value is divided by their combined area, so each of those polygons gets
#' the same density and the total is not counted more than once. Polygons with
#' no matching table row receive \code{NA} and a warning is issued. Duplicated
#' keys in the attribute table are an error.
#'
#' Areas are computed on the ellipsoid with \code{terra::expanse()}, whatever
#' the coordinate reference system of the layer. The cell size
#' \code{resolution} is, however, in the units of the layer's coordinate
#' reference system (degrees for longitude/latitude, usually metres otherwise),
#' and a warning is given if the layer is not in longitude/latitude. Each cell
#' takes the density of the polygon containing its centre, so the sum of
#' cell density times cell area can differ slightly from the original total.
#'
#' @param spatial_target A \code{terra::SpatVector}, \code{sf::sf} object, or a path string to a shapefile.
#' @param attribute_table A \code{data.frame}, \code{tibble}, or path string to a CSV file.
#' @param join_spatial Character. The indexing key column found within the spatial vector object.
#' @param join_attribute Character. The indexing key column found within the attribute table.
#' @param value_col Character. Numeric column containing values to evaluate for density calculation.
#' @param resolution Numeric. The cell size of the output raster, in the units of the layer's coordinate reference system.
#' @param output Optional character. A target filepath string (.tif or .asc) to write the raster to disk.
#'
#' @return A \code{terra::SpatRaster} object representing computed density surfaces.
#' @export
#'
#' @examples
#' \dontrun{
#' result <- generate_density_raster(
#'   spatial_target = standard_polygon_object,
#'   attribute_table = census_dataframe,
#'   join_spatial = "District_ID",
#'   join_attribute = "ID",
#'   value_col = "Population",
#'   resolution = 0.05
#' )
#' }
generate_density_raster <- function(
    spatial_target,
    attribute_table,
    join_spatial,
    join_attribute,
    value_col,
    resolution = 0.1,
    output = NULL
) {
    # 1. Input handling
    if (is.character(spatial_target)) {
        if (!file.exists(spatial_target)) stop("Specified spatial file target path does not exist.")
        polygons <- terra::vect(spatial_target)
    } else if (inherits(spatial_target, "SpatVector")) {
        polygons <- terra::deepcopy(spatial_target)
    } else if (inherits(spatial_target, "sf")) {
        polygons <- terra::vect(spatial_target)
    } else {
        stop("Input spatial_target must be a filepath string, sf object, or terra SpatVector.")
    }

    if (is.character(attribute_table)) {
        if (!file.exists(attribute_table)) stop("Specified attribute data table path does not exist.")
        census_data <- utils::read.csv(attribute_table, stringsAsFactors = FALSE)
    } else if (is.data.frame(attribute_table)) {
        census_data <- as.data.frame(attribute_table)
    } else {
        stop("Input attribute_table must be a filepath string or a valid data.frame structure.")
    }

    # 2. Schema validation
    if (!(join_spatial %in% names(polygons))) stop("Join column key missing from target spatial layer.")
    if (!(join_attribute %in% names(census_data))) stop("Join column key missing from target attribute dataset.")
    if (!(value_col %in% names(census_data))) stop("Target value column field missing from attribute dataset.")

    if (!terra::is.lonlat(polygons)) {
        warning("Spatial layer is not in longitude/latitude; 'resolution' is in the units of its CRS (",
                terra::linearUnits(polygons), " m per unit). Reproject with terra::project(x, \"EPSG:4326\") ",
                "if you intended degrees.")
    }

    # 3. Join by key (case- and whitespace-insensitive)
    poly_key   <- toupper(trimws(as.character(terra::values(polygons)[[join_spatial]])))
    table_key  <- toupper(trimws(as.character(census_data[[join_attribute]])))

    if (anyDuplicated(table_key)) {
        stop("Duplicated keys in attribute table: ",
             paste(unique(table_key[duplicated(table_key)]), collapse = ", "))
    }

    idx <- match(poly_key, table_key)
    if (anyNA(idx)) {
        warning("No table row for ", sum(is.na(idx)), " polygon(s): ",
                paste(unique(poly_key[is.na(idx)]), collapse = ", "), ". Their density will be NA.")
    }
    unused <- setdiff(table_key, poly_key)
    if (length(unused) > 0) {
        warning("Table rows with no polygon: ", paste(unused, collapse = ", "))
    }

    raw_val <- census_data[[value_col]][idx]
    value   <- suppressWarnings(as.numeric(raw_val))
    if (any(is.na(value) & !is.na(raw_val))) {
        warning("Some values could not be converted to numbers (check for thousands separators).")
    }
    polygons$joined_value <- value

    # 4. Geodesic areas; polygons sharing a key share the value by area
    polygons$area_km2 <- terra::expanse(polygons, unit = "km")
    if (any(polygons$area_km2 == 0, na.rm = TRUE)) {
        warning("Zero area elements detected within spatial shapes; density calculation forced to NA.")
    }
    key_area <- stats::ave(polygons$area_km2, poly_key, FUN = function(a) sum(a, na.rm = TRUE))
    polygons$density <- polygons$joined_value / key_area

    # 5. Rasterization (cell takes the value of the polygon containing its centre)
    template <- terra::rast(polygons, resolution = resolution)
    density_raster <- terra::rasterize(polygons, template, field = "density")

    # 6. Optional output
    if (!is.null(output)) {
        file_ext <- tolower(tools::file_ext(output))
        driver_type <- switch(file_ext,
            "tif"  = "GTiff",
            "tiff" = "GTiff",
            "asc"  = "AAIGrid",
            stop("Unsupported output format specified. Use .tif or .asc extensions.")
        )
        terra::writeRaster(density_raster, output, filetype = driver_type, overwrite = TRUE)
    }

    density_raster
}

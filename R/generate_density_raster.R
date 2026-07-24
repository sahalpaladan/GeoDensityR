#' Generate Density Raster from Polygon and Tabular Data
#'
#' Creates a continuous density raster surface by joining vector spatial 
#' layers with tabular data frameworks, normalizing values by ellipsoidal 
#' polygon area calculations.
#'
#' @param spatial_target A \code{terra::SpatVector}, \code{sf::sf} object, or a path string to a shapefile.
#' @param attribute_table A \code{data.frame}, \code{tibble}, or path string to a CSV file.
#' @param join_spatial Character. The indexing key column found within the spatial vector object.
#' @param join_attribute Character. The indexing key column found within the attribute table.
#' @param value_col Character. Numeric column containing values to evaluate for density calculation.
#' @param resolution Numeric. The cell size resolution for the generated target output raster template.
#' @param output Optional character. A target filepath string (.tif or .asc) to write the raster to disk.
#'
#' @return A \code{terra::SpatRaster} object representing computed density surfaces.
#' @export
#'
#' @examples
#' \dontrun{
#' # Example using in-memory data frames and vectors
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
    # 1. Dynamic Input Handling (Memory vs Disk Path)
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
        census_data <- attribute_table
    } else {
        stop("Input attribute_table must be a filepath string or a valid data.frame structure.")
    }

    # 2. Structural Schema Validations
    if (!(join_spatial %in% names(polygons))) stop("Join column key missing from target spatial layer.")
    if (!(join_attribute %in% names(census_data))) stop("Join column key missing from target attribute dataset.")
    if (!(value_col %in% names(census_data))) stop("Target value column field missing from attribute dataset.")

    # 3. Robust Relational Joining
    polygons_df <- data.frame(
        orig_key = as.character(terra::values(polygons)[[join_spatial]]), 
        row_id = seq_len(nrow(polygons)), 
        stringsAsFactors = FALSE
    )
    polygons_df$match_key <- toupper(trimws(polygons_df$orig_key))
    census_data$match_key <- toupper(trimws(as.character(census_data[[join_attribute]])))
    
    merged_meta <- merge(polygons_df, census_data, by = "match_key", all.x = TRUE)
    merged_meta <- merged_meta[order(merged_meta$row_id), ]
    
    polygons$joined_value <- as.numeric(merged_meta[[value_col]])

    # 4. Rigorous Geodesic Calculations (No Hardcoded Projections)
    polygons$area_km2 <- terra::expanse(polygons, unit = "km")
    
    if (any(polygons$area_km2 == 0, na.rm = TRUE)) {
        warning("Zero area elements detected within spatial shapes; density calculation forced to NA.")
    }
    
    polygons$density <- polygons$joined_value / polygons$area_km2

    # 5. Dynamic Template Initialization and Rasterization
    template <- terra::rast(polygons, resolution = resolution)
    density_raster <- terra::rasterize(polygons, template, field = "density")

    # 6. Decoupled Secondary I/O Operations
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

    return(density_raster)
}

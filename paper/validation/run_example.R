# Livestock density rasters for India with the released GeoDensityR (>= 0.2.2).
# Set data_dir to the folder that contains India_State_Boundary.shp (and its
# .shx/.dbf/.prj files) and livestock_counts.csv. Outputs are written to the
# current working directory.

library(terra)
library(GeoDensityR)
stopifnot(packageVersion("GeoDensityR") >= "0.2.2")

data_dir <- "."                                     # <- edit if needed
res      <- 0.05                                    # degrees
species  <- c("Cattle", "Buffalo", "Sheep", "Goat")

# ---- 1. Boundaries: the file is in Web Mercator (metres), so reproject ------
v <- project(vect(file.path(data_dir, "India_State_Boundary.shp")), "EPSG:4326")
stopifnot(is.lonlat(v))

# The 20th Livestock Census (fieldwork 2018-19) predates the separation of Ladakh
# from Jammu and Kashmir (31 October 2019), and the census row "Jammu and Kashmir"
# appears to cover both. Give Ladakh the same key so the count is spread over the
# combined area (polygons that share a key share the value in proportion to area).
# Set to FALSE only if you have a separate Ladakh row.
merge_ladakh <- TRUE
if (merge_ladakh) v$State_Name[v$State_Name == "Ladakh"] <- "Jammu and Kashmir"
cat("Polygons:", nrow(v), "\n")

# ---- 2. Counts: values like "36,438" are text, so strip the commas ----------
tab <- read.csv(file.path(data_dir, "livestock_counts.csv"), stringsAsFactors = FALSE)
for (sp in species) tab[[sp]] <- as.numeric(gsub(",", "", tab[[sp]]))
stopifnot(!anyNA(tab[, species]))

# ---- 3. Key check -------------------------------------------------------------
cat("Table rows with no polygon:", setdiff(tab$State, v$State_Name), "\n")   # expect none
cat("Polygons with no table row:", setdiff(v$State_Name, tab$State), "\n")   # expect none (Ladakh now shares the Jammu and Kashmir key)

# ---- 4. One density raster per species ----------------------------------------
dens <- lapply(species, function(sp) {
  generate_density_raster(
    spatial_target  = v,
    attribute_table = tab,
    join_spatial    = "State_Name",
    join_attribute  = "State",
    value_col       = sp,
    resolution      = res,
    output          = paste0(tolower(sp), "_density_", res, "deg.tif")
  )
})
names(dens) <- species
stack <- rast(dens)
names(stack) <- species
print(stack)

# ---- 5. Do raster totals match the census totals? ---------------------------------
check <- do.call(rbind, lapply(species, function(sp) {
  r    <- dens[[sp]]
  mass <- global(r * cellSize(r, unit = "km"), "sum", na.rm = TRUE)[[1]]
  data.frame(species      = sp,
             census_total = sum(tab[[sp]]),
             raster_total = round(mass),
             error_pct    = round(100 * (sum(tab[[sp]]) - mass) / sum(tab[[sp]]), 4))
}))
print(check)

# ---- 6. Plot ----------------------------------------------------------------------
png("livestock_density_maps.png", width = 2400, height = 2000, res = 300)
plot(stack, main = paste(species, "density (animals per km2)"), nr = 2, nc = 2)
dev.off()

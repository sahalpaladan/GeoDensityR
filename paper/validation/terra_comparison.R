# GeoDensityR (>= 0.2.2) versus an equivalent hand-written, vectorised terra script.

library(terra)
library(GeoDensityR)
stopifnot(packageVersion("GeoDensityR") >= "0.2.2")
if (!requireNamespace("bench", quietly = TRUE)) install.packages("bench")

data_dir <- "."                                     # <- edit if needed
species  <- "Cattle"
res      <- 0.05

v   <- project(vect(file.path(data_dir, "India_State_Boundary.shp")), "EPSG:4326")
# The 20th Livestock Census (fieldwork 2018-19) predates the separation of Ladakh
# from Jammu and Kashmir (31 October 2019), and the census row "Jammu and Kashmir"
# appears to cover both. Give Ladakh the same key so the count is spread over the
# combined area (polygons that share a key share the value in proportion to area).
# Set to FALSE only if you have a separate Ladakh row.
merge_ladakh <- TRUE
if (merge_ladakh) v$State_Name[v$State_Name == "Ladakh"] <- "Jammu and Kashmir"

tab <- read.csv(file.path(data_dir, "livestock_counts.csv"), stringsAsFactors = FALSE)
tab[[species]] <- as.numeric(gsub(",", "", tab[[species]]))

# Hand-written terra workflow
manual <- function(res) {
  p    <- v
  key  <- toupper(trimws(p$State_Name))
  tkey <- toupper(trimws(tab$State))
  p$val  <- tab[[species]][match(key, tkey)]
  p$area <- expanse(p, unit = "km")
  p$dens <- p$val / ave(p$area, key, FUN = function(a) sum(a, na.rm = TRUE))
  rasterize(p, rast(p, resolution = res), field = "dens")
}

pkg <- function(res) suppressWarnings(generate_density_raster(
  spatial_target = v, attribute_table = tab,
  join_spatial = "State_Name", join_attribute = "State",
  value_col = species, resolution = res))

# 1. Identical rasters?
a <- manual(res); b <- pkg(res)
same <- isTRUE(all.equal(as.vector(values(a)), as.vector(values(b))))
cat("Identical rasters:", same, "\n")

# 2. Time (median of repeated runs)
bm <- bench::mark(manual = manual(res), GeoDensityR = pkg(res),
                  iterations = 20, check = FALSE)
print(bm[, c("expression", "median", "itr/sec")])

# 3. Code length
cat("\nLines of code, manual workflow:", length(deparse(body(manual))), "\n")
cat("Lines of code, GeoDensityR call: 1 function call (6 arguments)\n")

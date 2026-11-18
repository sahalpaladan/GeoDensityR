# Cells, median run time and population error at four resolutions (cattle),
# using the released GeoDensityR (>= 0.2.2).

library(terra)
library(GeoDensityR)
stopifnot(packageVersion("GeoDensityR") >= "0.2.2")
if (!requireNamespace("microbenchmark", quietly = TRUE)) install.packages("microbenchmark")

data_dir <- "."                                     # <- edit if needed
species  <- "Cattle"
res_set  <- c(0.01, 0.025, 0.05, 0.10)
n_times  <- 10                                      # timing repetitions per resolution

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
vec_total <- sum(tab[[species]])

one_run <- function(res) {
  suppressWarnings(generate_density_raster(
    spatial_target  = v,
    attribute_table = tab,
    join_spatial    = "State_Name",
    join_attribute  = "State",
    value_col       = species,
    resolution      = res
  ))
}

rows <- lapply(res_set, function(res) {
  cat("Resolution", res, "...\n")
  r <- one_run(res)
  cells <- global(r, "notNA")[[1]]
  mass  <- global(r * cellSize(r, unit = "km"), "sum", na.rm = TRUE)[[1]]
  err   <- 100 * (vec_total - mass) / vec_total     # signed: positive = raster total is lower
  mb <- microbenchmark::microbenchmark(one_run(res), times = n_times)
  data.frame(resolution = res, cells = cells, time_ms = median(mb$time) / 1e6,
             raster_total = round(mass), error_pct = err)
})
out <- do.call(rbind, rows)
print(out, digits = 6)
write.csv(out, "resolution_table.csv", row.names = FALSE)

cat("\n| Resolution (degrees) | Cells | Time (ms) | Population error (%) |\n")
cat("|:--------------------:|------:|----------:|---------------------:|\n")
for (i in seq_len(nrow(out))) {
  cat(sprintf("| %-20s | %s | %.1f | %.4f |\n",
              format(out$resolution[i]),
              format(out$cells[i], big.mark = ","),
              out$time_ms[i],
              out$error_pct[i]))
}

cat("\nR", R.version.string, "| terra", as.character(packageVersion("terra")),
    "| GeoDensityR", as.character(packageVersion("GeoDensityR")),
    "| cores:", parallel::detectCores(), "|", Sys.info()[["sysname"]], Sys.info()[["machine"]], "\n")

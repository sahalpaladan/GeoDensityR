# Not run by me (no R here). Run with devtools::test() and fix any failure.

make_polys <- function() {
  # Three 1 x 1 degree squares; "A" is made of two separate polygons.
  p <- terra::vect(
    c("POLYGON((0 0, 1 0, 1 1, 0 1, 0 0))",
      "POLYGON((1 0, 2 0, 2 1, 1 1, 1 0))",
      "POLYGON((2 0, 3 0, 3 1, 2 1, 2 0))"),
    crs = "EPSG:4326"
  )
  p$id <- c("A", "B", "A")
  p
}

make_tab <- function() data.frame(ID = c("a", "B"), n = c(100, 50), stringsAsFactors = FALSE)

raster_total <- function(r) {
  terra::global(r * terra::cellSize(r, unit = "km"), "sum", na.rm = TRUE)[[1]]
}

run <- function(polys = make_polys(), tab = make_tab(), res = 0.1) {
  generate_density_raster(polys, tab, "id", "ID", "n", resolution = res)
}

test_that("returns a SpatRaster and matches keys regardless of case", {
  r <- run()
  expect_s4_class(r, "SpatRaster")
  expect_gt(terra::global(r, "notNA")[[1]], 0)
})

test_that("polygons sharing a key split the value by area (no double counting)", {
  r <- run()
  # 100 (key A, two polygons) + 50 (key B) = 150, not 250
  expect_equal(raster_total(r), 150, tolerance = 0.01)
})

test_that("a polygon without a table row gives a warning and NA", {
  tab <- make_tab()[make_tab()$ID == "a", ]
  expect_warning(r <- run(tab = tab), "No table row")
  expect_equal(raster_total(r), 100, tolerance = 0.01)
})

test_that("table rows without a polygon give a warning", {
  tab <- rbind(make_tab(), data.frame(ID = "Z", n = 5))
  expect_warning(run(tab = tab), "no polygon")
})

test_that("duplicated keys in the table are an error", {
  tab <- rbind(make_tab(), data.frame(ID = "B", n = 1))
  expect_error(run(tab = tab), "Duplicated keys")
})

test_that("values that cannot be converted to numbers give a warning", {
  tab <- make_tab()
  tab$n <- c("1,000", "50")
  expect_warning(run(tab = tab), "converted")
})

test_that("a layer not in longitude/latitude gives a warning", {
  p <- terra::project(make_polys(), "EPSG:3857")
  expect_warning(run(polys = p, res = 100000), "not in longitude/latitude")
})

test_that("missing columns are errors", {
  expect_error(generate_density_raster(make_polys(), make_tab(), "nope", "ID", "n"), "Join column key missing")
  expect_error(generate_density_raster(make_polys(), make_tab(), "id", "nope", "n"), "Join column key missing")
  expect_error(generate_density_raster(make_polys(), make_tab(), "id", "ID", "nope"), "value column")
})

test_that("output file is written as GeoTIFF", {
  f <- tempfile(fileext = ".tif")
  generate_density_raster(make_polys(), make_tab(), "id", "ID", "n", resolution = 0.1, output = f)
  expect_true(file.exists(f))
})

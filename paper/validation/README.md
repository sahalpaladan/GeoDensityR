# Validation scripts for the GeoDensityR paper

These scripts reproduce the numbers and the figure in `../paper.md` using the released
GeoDensityR (version 0.2.2 or later).

## Files

| File | Purpose |
|---|---|
| `run_example.R` | Builds cattle, buffalo, sheep and goat density rasters at 0.05 degrees, checks raster totals against census totals, and saves `livestock_density_maps.png` (Figure 1 of the paper, before panel labels). |
| `resolution_table.R` | Cell count, median run time and population error at 0.01, 0.025, 0.05 and 0.10 degrees (cattle). |
| `terra_comparison.R` | Compares `generate_density_raster()` with an equivalent hand-written `terra` script. |
| `livestock_counts.csv` | State-wise cattle, buffalo, sheep and goat counts, 20th Livestock Census, from the Press Information Bureau release "Census for cows, buffaloes, goats and sheeps" (Release ID 2205263, 17 December 2025). Dadra and Nagar Haveli and Daman and Diu are summed into one row to match the boundary layer. |

## Boundary data

The state boundary layer is not included in this repository. It comes from
Anuj Tiwari, *India State and Country Shapefile (Updated Jan 2020)*,
<https://github.com/AnujTiwari/India-State-and-Country-Shapefile-Updated-Jan-2020>
(files `India_State_Boundary.shp`, `.shx`, `.dbf`, `.prj`). That repository has no licence file and
says the data may be used "for personal purposes", so we do not redistribute it. Download the four
files and place them in this folder before running the scripts.

The layer is in Web Mercator; the scripts reproject it to longitude/latitude. It contains 37
polygons, including two for Puducherry and a separate Ladakh polygon. The census table has no
Ladakh row, so the scripts give Ladakh the key of Jammu and Kashmir (`merge_ladakh <- TRUE`).

## Running

```r
install.packages("GeoDensityR")   # 0.2.2 or later
setwd("path/to/this/folder")
source("run_example.R")
source("resolution_table.R")
source("terra_comparison.R")
```

Timings depend on the machine. The paper reports a Windows x86-64 workstation with 32 logical
cores, R 4.6.0 and terra 1.9.50.

---
title: 'GeoDensityR: Generating density rasters from polygon and census data in R'
tags:
  - R
  - spatial analysis
  - rasterization
  - census data
  - population density
  - spatial epidemiology
authors:
  - name: Sahal Paladan
    orcid: 0009-0005-0120-128X
    affiliation: 1
  - name: Mohammed Mudassar Chanda
    orcid: 0000-0002-5727-8658
    corresponding: true
    affiliation: 1
affiliations:
  - name: ICAR-National Institute of Veterinary Epidemiology and Disease Informatics (ICAR-NIVEDI), Bengaluru, Karnataka, India
    index: 1
date: 6 November 2026
bibliography: paper.bib
---

# Summary

Census, survey and surveillance counts are almost always published per administrative unit (districts, states, census tracts), whereas environmental covariates such as climate, vegetation and elevation are distributed as regular raster grids. Combining the two requires turning boundary-constrained counts into a raster surface on a common grid. `GeoDensityR` is an R package that automates this step. It joins a table of attribute values to a polygon layer by a shared key, computes each polygon's area on a reference ellipsoid, divides the attribute value by that area to obtain a density, and writes the density into a raster of user-specified resolution. Inputs can be in-memory objects or file paths, and the output is a `SpatRaster` from the `terra` package [@terra] that can be stacked directly with other covariates.

# Statement of need

Area-normalized densities (for example animals per km^2^) are routinely needed as predictors in species distribution models, disease risk mapping and exposure assessment. In our own work on host-vector interfaces for tick-borne diseases, livestock counts reported per state had to be converted to density surfaces and aligned with climate rasters. Doing this manually in R involves several error-prone steps: matching keys between a data frame and a polygon layer, handling unmatched or duplicated keys, choosing how to compute area, rasterizing, and keeping units consistent. Each step is simple, but repeating them across many species, years and regions leads to ad hoc scripts that are difficult to reproduce.

`GeoDensityR` wraps these steps in a single documented function, `generate_density_raster()`, which checks that the join and value columns exist before processing. A key design choice is that polygon areas are computed on the ellipsoid rather than after projection to a planar coordinate system. For study regions spanning many degrees of latitude and longitude, no single projection preserves area everywhere, so planar areas introduce distortion into the denominator of the density. Computing geodesic areas avoids having to choose a projection for this purpose. The package targets researchers in epidemiology, ecology and demography who work in R and need reproducible, scriptable workflows rather than interactive GIS tools.

# State of the field

The `terra` package [@terra] provides the building blocks (`rasterize()`, `expanse()`, `merge()`), and `sf` [@sf] provides vector data handling and area calculation. A user can reproduce the density calculation of `GeoDensityR` by combining these functions manually; the package does not introduce new low-level capabilities, and relies on `terra` for all spatial operations. Its contribution is a validated, documented and tested workflow for one common task.

Other tools address related but different problems. The `areal` package [@areal] implements areal-weighted interpolation between two sets of polygons, and pycnophylactic interpolation [@tobler1979] produces smooth, mass-preserving surfaces from polygon counts. Both are better suited when counts must be redistributed across overlapping or finer-scale units. `GeoDensityR` makes a simpler assumption: density is uniform within each source polygon, and each raster cell takes the density of the polygon containing its centroid. This is the appropriate transformation when the goal is a covariate layer expressing the per-area intensity of an administrative-level count, and it is deliberately not a dasymetric or mass-preserving method. Users who need cell-level estimates that sum to the original totals should use one of the interpolation approaches above. We built a separate package rather than contributing to these because the intended scope (key join, ellipsoidal normalization, rasterization) is narrow and does not fit within the aims of the interpolation packages.

# Software design

The main function takes a polygon layer (`spatial_target`), a data frame (`attribute_table`), the names of the key columns in each (`join_spatial`, `join_attribute`), the value column (`value_col`) and an output `resolution` in the units of the layer's coordinate reference system:

```r
library("GeoDensityR")
dens <- generate_density_raster(
  spatial_target  = vector_polygon_layer,
  attribute_table = demographic_dataframe,
  join_spatial    = "District_ID",
  join_attribute  = "ID",
  value_col       = "Total_Population",
  resolution      = 0.01
)
```

Internally the function (1) accepts a `terra` `SpatVector`, an `sf` object or a file path for the polygons, and a data frame or CSV path for the table, (2) joins the table to the polygons by key, matching keys without regard to case or surrounding whitespace, (3) computes polygon areas on the ellipsoid using `terra::expanse()`, (4) divides the value by the area to obtain density, and (5) rasterizes the result onto a regular grid using `terra::rasterize()`, which assigns each cell the value of the polygon containing its centroid. The result can optionally be written to a GeoTIFF or ASCII grid. Polygons without a matching table row receive `NA`. The package depends only on `terra` and base R's `tools`, keeping installation simple, and is distributed on CRAN (version 0.2.2, <https://doi.org/10.32614/CRAN.package.GeoDensityR>) under the MIT license. Unit tests use `testthat`, and a vignette demonstrates a complete example.

**Limitations.** Within each polygon the density is constant, so surfaces show sharp discontinuities at boundaries and carry no information on within-unit heterogeneity (for example uninhabited land). Cell values multiplied by cell area will not in general sum to the original counts; in our test at 0.05 degrees the national total differed by 0.03%. Results depend on the resolution chosen relative to polygon size, and polygons smaller than a cell may be missed by the centroid rule.

# Research impact statement

As a demonstration we used `GeoDensityR` with state boundaries of India (a layer updated in January 2020, with Ladakh as a separate territory) [@tiwari2020] and state-level counts of cattle, buffalo, sheep and goats from the 20th Livestock Census [@pib2025], producing density surfaces at 0.05 degree resolution (\autoref{fig:livestock}). These layers are being used as host-density covariates in a project on climatic drivers of Crimean-Congo haemorrhagic fever and Kyasanur Forest disease risk.

![Area-normalized density surfaces (animals per km^2^) for (a) cattle, (b) buffalo, (c) sheep and (d) goats, generated with `GeoDensityR` from state-level counts of the 20th Livestock Census. Jammu and Kashmir and Ladakh share one value, because the census count covers both.\label{fig:livestock}](figure1.png)

**Population preservation.** Because each cell takes the density of the polygon containing its centroid, the sum of cell density multiplied by cell area can differ from the original total where polygon edges cut through cells. We checked this using cattle counts from the 20th Livestock Census for India on a 0.05 degree grid. The published table lists 36 States and Union Territories. We summed its two rows for Dadra and Nagar Haveli and for Daman and Diu, which form a single unit in the boundary layer, giving 35 rows, while the boundary layer has 37 polygons. Puducherry consists of two polygons, and the table has no row for Ladakh, which became a separate Union Territory in October 2019, so we take the Jammu and Kashmir row to include it and let those two polygons share one key. The original total is 193,500,987 animals. The raster-derived total, computed as cell density multiplied by ellipsoidal cell area, was 193,438,993 animals, a difference of 61,994 animals (0.032%). The same check for buffalo, sheep and goats gave differences of 0.032%, 0.062% and 0.053%.`GeoDensityR` deliberately keeps the native `terra` behaviour rather than silently adjusting values. Users who need the total preserved exactly can multiply the raster by the factor $\omega = M_V / M_R$. A single global factor restores the national total but not the totals of individual states.

**Resolution sensitivity.** We repeated the analysis at four resolutions (\autoref{tab:resolution}). Timings are medians of 10 runs on a Windows x86-64 workstation with 32 logical cores (R 4.6.0, `terra` 1.9.50, `GeoDensityR` 0.2.2). The population error was below 0.06% at every resolution and was smallest at 0.01 degrees. Run time changed little across a hundredfold range in cell count because most of it is a fixed cost: computing the ellipsoidal areas of the 37 polygons (about 1.15 million vertices in total) with `terra::expanse()` took a median of 0.60 s on its own. The remaining steps, mainly rasterization, took about 0.12 s at 0.10 degrees and about 0.60 s at 0.01 degrees. Because the centroid rule can add or drop cells at polygon edges, the error is signed and need not decrease monotonically.

| Resolution (degrees) | Cells | Time (ms) | Population error (%) |
|:--------------------:|------:|----------:|---------------------:|
| 0.01                 | 2,906,037 | 1201.7 | 0.0007 |
| 0.025                | 464,926 | 850.2 | 0.0133 |
| 0.05                 | 116,220 | 763.0 | 0.0320 |
| 0.10                 | 29,050 | 721.0 | 0.0567 |

Table: Effect of grid resolution on non-empty cell count, median processing time over 10 runs and population error (cattle, 20th Livestock Census, India). \label{tab:resolution}

**Comparison with a hand-written `terra` script.** For the same polygons, census table and 0.05 degree grid on the same machine, we compared `GeoDensityR` with an equivalent vectorized `terra` script (key matching, `expanse()`, an area-weighted division and `rasterize()`, about ten lines of code). The two produced identical rasters, and their median run times over 20 runs were similar (755 ms for the hand-written script and 764 ms for `GeoDensityR`). This is expected, because `GeoDensityR` calls `terra` internally, so the package offers no speed advantage. Its benefit is that the workflow becomes a single call with checks on the inputs and no user-managed intermediate objects.

**Status and reproducibility.** `GeoDensityR` was released on CRAN on 17 November 2026 (version 0.2.2) with a vignette and unit tests, and is checked by CRAN on Linux and Windows. The scripts that reproduce the validation and timing results, together with the census table, are in the repository (`paper/validation`), so reviewers and users can rerun them.

# AI usage disclosure

Generative AI was used in this work. Claude (Anthropic), accessed through claude.ai in November 2026 (model: Claude Sonnet 5.5), was used to (1) convert and edit the manuscript into the JOSS format, including this text and the bibliography, (2) write and revise code, namely the 0.2.2 revision of `generate_density_raster()` (duplicate-key handling, input warnings and the coordinate-system check), the unit tests, the vignette, the README, the contributing guide, and the R and Python scripts used for the validation, and (3) suggest debugging and release steps. In earlier work on the original package code and on the earlier version of this manuscript, Gemini (Google; model: Gemini 4 Hydrogen) was used to correct code and to edit language and grammar. The authors reviewed the generated material and checked it by running the automated tests, `R CMD check` on Linux and on the CRAN Windows builder, an independent re-implementation of the population check in Python, and a rerun of all reported results with the released package.

# Acknowledgements

This work was supported by the Indian Council of Medical Research (ICMR) under the project "Identifying the association between climatic variables, CCHF, KFD and their vectors for the development of risk maps under present and future climate change scenarios using GIS, remote sensing and novel modeling approaches" (grant 6/9-7(331)/2023/ECD-II). We thank the Director of ICAR-NIVEDI, Bengaluru, for institutional and infrastructural support.

# References

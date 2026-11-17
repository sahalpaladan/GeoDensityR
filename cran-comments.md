## Resubmission

This is a resubmission with the version number increased to 0.2.2 (0.2.1 was not published). The previous submission reported an invalid file URI (`CONTRIBUTING.md`, linked from `README.md`). The link in `README.md` is now an absolute URL to the file on GitHub.

## Release summary

This is an update from 0.2.0 to 0.2.2. Changes:

* Polygons that share a key now share the value in proportion to their area. Previously each polygon received the full value, so the count was used more than once.
* New warnings for polygons without a table row, table rows without a polygon, values that cannot be converted to numbers, and layers that are not in longitude/latitude.
* Duplicated keys in the attribute table are now an error.
* Added a vignette and unit tests.

## Test environments

* Linux (conda), R 4.5.3
* Windows, R Under development (2026-11-16 r90914 ucrt) (win-builder): Status OK

## R CMD check results

0 errors | 0 warnings | 0 notes

## Downstream dependencies

There are no downstream dependencies.

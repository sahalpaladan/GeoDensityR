# Contributing to GeoDensityR

Thank you for your interest in improving GeoDensityR.

## Reporting bugs and asking questions

Open an issue at <https://github.com/sahalpaladan/GeoDensityR/issues>. Please include:

* a minimal example that reproduces the problem (a few polygons and a small table are enough),
* the output of `sessionInfo()`,
* what you expected to happen and what happened instead.

Questions about how to use the package are welcome as issues too.

## Suggesting changes

1. Fork the repository and create a branch for your change.
2. Make the change and add or update a test in `tests/testthat/`.
3. Run `devtools::document()`, `devtools::test()` and `devtools::check()`, and make sure they finish without errors or warnings.
4. Add a line describing the change to `NEWS.md`.
5. Open a pull request that explains what you changed and why.

## Code style

Follow the style of the existing code: clear argument names, informative error and warning messages, and `terra::` prefixes for functions from other packages.

## Conduct

Please be respectful and constructive in all discussions.

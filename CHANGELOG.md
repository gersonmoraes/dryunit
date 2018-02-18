Changelog
=========

0.5.1
-----

  * Adding support for `jbuilder runtest` in the templates
  * Fix for causal exceptions when persisting cache
  * Removed all ppx-related code
  * Optimizing for empty suites
  * Simplifying testsuite names


0.5.0
-----

  * The main restrictions (originally designed for `ppx_dryunit`) are gone. Using *relative paths* with `--cache-dir` and running outside build directories is now allowed.
  * Command `dryunit` outputs correctly to stdout (whenever a target list is absent).
  * Init templates were fixed so a file called `"tests.ml"` will be detected out of the box.
  * Small stability fix for bytes manipulation

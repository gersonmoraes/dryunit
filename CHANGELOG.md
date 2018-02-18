Changelog
=========

0.6.0
-----

  * Integrating incremental test execution with `jbuilder runtest`
  * Fix for causal exceptions when persisting cache
  * Removed all ppx and cppo related code (now dryunit only deps on cmdliner)
  * When the suite is empty, no bootstrap is generated
  * Names for testsuites were simplified


0.5.0
-----

  * The main restrictions (originally designed for `ppx_dryunit`) are gone. Using *relative paths* with `--cache-dir` and running outside build directories is now allowed.
  * Command `dryunit` outputs correctly to stdout (whenever a target list is absent).
  * Init templates were fixed so a file called `"tests.ml"` will be detected out of the box.
  * Small stability fix for bytes manipulation

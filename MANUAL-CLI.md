# The `dryunit` command

Dryunit's core functionallity is provided through the extension `ppx_dryunit`.
The package `dryunit` contains an *optional* command line interface to help
automate workflows and enforce the project's philosophy and latest conventions.

Still, this is a tool to help you create bootstrap-free test suites using the
most common OCaml test frameworks. It follows the latest conventions for the
Dryunit project, which means two things:

- We believe nobody should be forced to remember conventions about
infraestructure, that's why an updated interactive cli might prove useful for
most users.
- It's tempting to implement the automation yourself, *since it is small enough*.
Just be warned that `ppx_dryunit` is still evolving and updates may require
changes in your workflow. We believe even that can be reduced with a cli.



Available subcommands:

- **--help**: Display this help

-  **--version**: Display `dryunit`'s command-line version

-  **clean**: Remove cached data. By default, `ppx_dryunit` only processes each
test file once, and keeps track of modifications with timestamps. All cache is
stored under the `.dryunit` directory at the root your repository. This avoids
conflicts with some building systems, but also means you need to be aware of
some evolving conventions. To make that learning curve faster, the `--clean`
 parameter is provided.

-  **gen "alcotest|ounit"**: Use this command to generate the main executable
with bootstrap code for `Alcotest`  (recommended for new projects) or `OUnit`
(for legacy code using v2). By default it outputs to stdout. You can change this
setting `--output file`, or the short version, `-o file`. It's important that
this file is recreated with a random variation at each build. This forces your
build system to reprocesse the file, activating the extension and all detection
logic.

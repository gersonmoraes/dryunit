# Dryunit

Dryunit is a tool that allows you to test OCaml code using *Convention over Configuration*.

Your tests are put first, so TDD can get out of your way. We wanted to get the project right and be *dry*. That is why the first implementations do not implement a test framework. You are invited to use [Alcotest][] or [OUnit][] for that.

The big advantage of traditional testing over alternatives is that ***you get to use pure OCaml***. Free of enhancements. Using the exact same syntax you do everything else. Your tests are independent but can use anything in their context. *It's just OCaml, do whatever way you want*.


## Conventions

Conventions are minimal, but necessary. They allow for a good visual distinction when you are interacting with non-test code. They also make configuration simpler.

- All files containing tests should be either called `tests.ml` or `something_tests.ml`.
- All test function names must start with `test`.
- By default, test executables are created per directory and are called `main`. But you do not need to ever see this file.

## Quickstart

Install the command line in your system:

```
opam install dryunit
```

Dryunit works with jbuilder out of the box:

```
mkdir tests
dryunit init > tests/jbuild
```

No other configuration is required. The generated rules will define the executable `tests/main.exe` ready for the default framework. You can also make the framework explicit by using `dryunit init alcotest`.

## Configuration

This is the output of the command `dryunit init`:

```
(executables
 ((names (main))
  (libraries (alcotest))))

(rule
 ((targets (main.ml))
  (deps ( (glob_files *tests.ml) (glob_files *Tests.ml) ))
  (action  (with-stdout-to ${@} (run dryunit gen
    --framework alcotest
    ;; --filter "space separated list"
    ;; --ignore "space separated list"
    ;; --ignore-path "space separated list"
  )))))
```

It defines an executable `main.exe` based on the default framework. A rule to generate and update this file is also defined. In comments you see some configurations passed to the executable before build. For more definitions use `dryunit help` or `dryunit COMMAND - - help`. 

It also shows helpful information on comments, describing how to setup simple changing detection for a list of files, and in the end, how to filter or ignore some tests.



## The extension ppx_dryunit

This project was originated as a PPX. It is still available as an optional package and does the same thing as the command line, plus the possibility to detect tests only in the current file, which is the default.

The simplest way is to use it add this line to the end of your file `main.ml`:

```
let () = [%dryunit]
```



But that generates a default configuration. But since it could change in the feature, it is  better to define some configurations. Arguments are given using a record. All fields are optionals and might be out of order.

```ocaml
let () =
  [%dryunit
    { cache_dir   = ".dryunit"
    ; cache       = true
    ; framework   = "alcotest"
    ; ignore      = ""
    ; filter      = ""
    ; detection   = "file"
    ; ignore_path = "self"
    }
  ]
```



## Implementation details

- At build time, dryunit will check anything that looks like a test file in the build context and check its internal cache mechanism for preprocessed suites.
- If none is found, an instance of OCaml parser will be created to extract a structured representation of the test file.
- Cache is done in one file for the whole directory. Updated according to timestamps. Default directory is (`_build/.dryunit`).
- The extension does nothing if outside a build directory.



[alcotest]: https://github.com/mirage/alcotest
[ounit]: http://ounit.forge.ocamlcore.org/documentation.html

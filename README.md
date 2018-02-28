# Dryunit

Dryunit is a detection tool for unit testing in OCaml that is focused in *Convention over Configuration*.

## Why should you use it?



#### Dryunit is non-intrusive and nearly invisible

Your tests are put first and this boosts TDD in a very seamless way. Dryunit stays invisible once you setup the building system and requires no changes over the original test code, provided that you use minimal naming conventions.

It will not affect your OCaml code, add complexy layers nor keep you from using any feature in OCaml, because it's simply not going to be in your code. There's no need for PPX's nor extra libraries to import.



#### Dryunit is not a testing framework

It just detects new tests as you write them, and setup the bootstrap code for the actual test framework - *it takes care of writing the main file of a test executable*. You can write tests based on [Alcotest][] or [OUnit][].

If for whatever reason you would like to stop using Dryuniy, you can migrate back to manual boostrapping instantaneously by picking the latest bootstrapping code auto generated and commiting it to source control.



#### Using traditional testing frameworks matters

There's something about the simplicity and predictability of traditional testing frameworks producing self contained test executables from pure OCaml code. It's fascinating.

Different from alternative approaches, in traditional frameworks the *test code is not special*: there's no no enhanced syntax or rewriting that could potentially get in the way of your tooling. Which in term, means autocompletion and linting works as in any other piece of pure OCaml code.


## Conventions

Conventions are minimal, but necessary. They allow for a good visual distinction when you are interacting with non-test code. They also make configuration simpler.

- All files containing tests should be either called `tests.ml` or `something_tests.ml`.
- All test function names must start with `test`.
- By default, test executables are created per directory and are called `main`. But you do not need to ever see a `main.ml` file.


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

*(Tip: You can also make the framework explicit by using `dryunit init alcotest`.)*



No other configuration is required. When you are ready to run the tests, run:

````
jbuilder runtest
````



Sometimes you will want to execute a specific test executable passing some parameters. We do that for various reasons, like changing verbosity or output format. By default, all dryunit tests executables are called `main.exe`, so if you want to run a test passing a parameter, you can use `jbuilder exec`:

```
jbuilder exec tests/main.exe -- -v
```



## Configuration

This is the output of the command `dryunit init`:

```
(executables
 ((names (main))
  (libraries (alcotest))))

(rule
 ((targets (main.ml))
  (deps ( (glob_files {tests.ml,*tests.ml,*Tests.ml}) ))
  (action  (with-stdout-to ${@} (run dryunit gen
    --framework alcotest
    ;; --filter "space separated list"
    ;; --ignore "space separated list"
    ;; --ignore-path "space separated list"
  )))))

(alias
  ((name runtest)
   (deps (main.exe))
   (action (run ${<}))
  ))
```

As you see, this is the place to customize how the detection should behave is this file. The definitions in the comments provide a template for common filters, but you can find more information about customizations using `dryunit help` or `dryunit COMMAND - - help`.


## Implementation details

- At build time, dryunit will check anything that looks like a test file in the build context and check its internal cache mechanism for preprocessed suites.
- An instance of the OCaml parser will be made to extract a structured representation of each new or modified test files.
- Cache is done in one file for the whole directory. Updated according to timestamps and compiler version. Default directory is (`_build/.dryunit`), but this can be changed by passing a relative path to `--cache-dir`.



[alcotest]: https://github.com/mirage/alcotest
[ounit]: http://ounit.forge.ocamlcore.org/documentation.html

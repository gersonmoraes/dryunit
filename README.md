# Dryunit

>  Dryunit is a tool that allows you to test OCaml code using *Convention over Configuration*.

Your tests are put first, so TDD can get out of your way. We wanted to get the project right and be *dry*. That's why the first implementations of does not implement a test framework. You are invited to use [Alcotest][] or [OUnit][] for that.

The big advantage of traditional testing over alternatives is that ***you get to use pure OCaml***. Free of enhancements. Using the exact same syntax you do everything else. Your tests are independent but can use anything in their context. *It's just OCaml, do whatever way you want*.


## Conventions

Conventions are minimal, but necessary. They allow for a good visual distinction when you are interacting with non-test code. They also make configuration simpler.

- All files containing tests should be either called `tests.ml` or `something_tests.ml`.
- All test function names must start with `test`.
- By default, test executables are created per directory and are called `main`.

## Quickstart

Install the command line in your system:

```
opam install dryunit
```

Dryunit works with jbuilder out of the box:

```
mkdir tests
dryunit alcotest > tests/jbuild
```

You don't need any other configuration. The generated rules will define the executable `tests/main.exe` ready for Alcotest.

You could also define the framework to initialize your tests using `--framework ounit`. Don't worry, this and other definitions are easy to customize in the generated file.  For more information, use (`dryunit --help`).

## Filtering tests

This is the content of the command `dryunit init`:

```
(executables
 ((names (main))
  (libraries (alcotest))))

(rule
 ((targets (main.ml))
  (deps ( (glob_files *_tests.ml) (glob_files *_Tests.ml) ))
  (action  (with-stdout-to ${@} (run dryunit gen
    --framework alcotest
    ;; --filter "space separated list"
    ;; --ignore "space separated list"
    ;; --ignore-path "space separated list"
  )))))
```



It defaults to a configuration for a test executable `main.exe` based on Alcotest. By default, this file does not need to be created among your test files.

It also shows helpful information on comments, describing how to setup simple changing detection for a list of files, and in the end, how to filter or ignore some tests.


**Detecting only the tests in one file**

If you think detecting all tests in the directory is overkill for your needs, let me talk to you about `ppx_dryunit`.

If you don't want to keep a list of current test files in the configuration, you need to create the file `main.ml` in the same directory your tests live. This file ***should never be cached*** - it needs to be recompiled at every build. To make sure jbuilder does that it, there must be a random modification between builds.

Here's a template for a task in the Makefile:

```
dryunit:
	@dryunit gen --framework alcotest > tests/main.ml

test: dryunit
	...
```



Since this file will change frequently, you should put it in the list of ignored files in your VCS.



## How it works

The project has two main components:

  - The command line `dryunit`: the main user interface, responsible for the configuration and the pluggable workflow.
  - The extension `ppx_dryunit`: it does all the *"heavy lifting"*, including test detection, caching and Ast rewriting.


### Caching

The **caching** is important because the main executable needs to be re generated with some random modification at build time.

More importantly, the detection is done by calling a shell instance to ask OCaml parser to generate a structured representation of each test file. This adds an extra cost and should not be done for unmodified files. That's why the extension will dump the memory representation of the detected test suites in a cache file.

The primary form to detect changes is the timestamp of the test file. This is why by default, you can't detect tests from the file that activates the extension.

The cache is also aware of the version of the compiler used at each build, so executing `opam switch` doesn't break nor removes existing cache.

###  How DRY can you be?

The initial idea for the project was to create a nearly invisible test framework that would require no bootstrap code whatsoever. But to be truly dry you shouldn't need to change existing test code, build system nor frameworks.

This is a simplified version of Alcotest's sample test at the time of writing.

```ocaml
module MyLib = struct
  let capit letter = Char.uppercase letter
  let plus int_list = List.fold_left (fun a b -> a + b) 0 int_list
end

let test_capit () =
  Alcotest.(check char) "same chars"  'A' (Mylib.capit 'a')

let test_plus () =
  Alcotest.(check int) "same ints" 7 (Mylib.plus [1;1;2;3])
```

All functions starts with test and must be in the same directory of the file used to activate `ppx_dryunit`. If you want to create it manually, it looks like:

```ocaml
(*
  This file is supposed to be generated before build with a random ID.
  ID = 597588864186
*)
let () =
  [%dryunit
    { cache_dir   = ".dryunit"
    ; cache       = true
    ; framework   = "alcotest"
    ; ignore      = ""
    ; filter      = ""
    ; detection   = "dir"
    ; ignore_path = "self"
    }
  ]
```

If you just need to detect tests from one file, you can skip the command line and add the code above at the end of your main executable, with a slight change: `detection = "file"`.

### Under the hood

When processing the extension, the following happens:

- Dryunit checks if it's running from a `*build/*` directory, and returns `()` otherwise.

- Look at the directory where the extension was declared and find all `*.ml` files other than the current file.

- Extract a structured representation of each file, using OCaml's parser. This is fast, but produce boilerplate.

- Create a test suite with all module-level functions starting with `"test"`.

- Replace `[%dryunit... ]` in the AST with the apropriate code to bootstrap Alcotest.



## The future of the project

This project is *framework independent*. It changes the AST, but relies on the user environment to provide and validate the appropriate dependencies. The project itself remains *light*, even if support for new test frameworks supporting similar workflows is added in the future.

This is project is *low maintenance*. Thanks to OCaml's parser and the [Migrate-Parsetree](https://github.com/ocaml-ppx/ocaml-migrate-parsetree) project, this ppx  knows very little about the actual source syntax and already works on all major OCaml versions supporting ppx.

[alcotest]: https://github.com/mirage/alcotest
[ounit]: http://ounit.forge.ocamlcore.org/documentation.html

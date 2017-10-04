# Dryunit

Dryunit is a small tool that detects your unit tests and autogenerate the correspondent bootstrapping code on the fly in your build directory.

As a result, you get to use plain old OCaml and all the tooling you already use. It currently works with Alcotest and OUnit and has a template to simplify jbuild integration.

## Quickstart

Install the project in your system:

```
opam install dryunit
```

If you use jbuilder, you can use the command  `dryunit init` to generate a jbuild template config. For example, the commands below will generate the executable `tests/main.exe` for tests based on alcotest:

```
mkdir tests
dryunit init > tests/jbuild
```

That will make jbuilder generate the file "tests/main.ml" in your build directory. To add tests, just write a function with a name stating with "test" in any file inside the tests directory.

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

````ocaml
module MyLib = struct
  let capit letter = Char.uppercase letter
  let plus int_list = List.fold_left (fun a b -> a + b) 0 int_list
end

let test_capit () =
  Alcotest.(check char) "same chars"  'A' (Mylib.capit 'a')

let test_plus () =
  Alcotest.(check int) "same ints" 7 (Mylib.plus [1;1;2;3])
```

All functions starts with test and must be in the same directory of the file used to activate `ppx_dryunit`. If you want to create it manually, it looks like :

```ocaml
(*
  This file is supposed to be generated before build with a random ID.
  ID = 597588864186
*)
let () =
  [%dryunit
    { cache_dir = ".dryunit"
    ; cache     = true
    ; framework = "alcotest"
    ; ignore    = ""
    ; filter    = ""
    ; detection = "dir"
    }
  ]
```

If you just need to detect tests from one file, you can skip the command line and add the code above at the end of your main executable, with a slight change: `detection = "file".

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

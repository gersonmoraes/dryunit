# Dryunit

`ppx_dryunit` is an OCaml extension that automates bootstrapping code at build time for the main unit test frameworks in ecosystem. Currently, it supports both OUnit and Alcotest.  It uses a few conventions to detect and setup the testsuites, that can be written in good ol' OCaml, hassle-free.


### How DRY can you be?

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
````



To run this, create a new file in the same directory with this line:

```ocaml
let () = [%alcotest]
```

The only convention here is that all unit tests must start with the name "test". So if you need to disable a test `test_feature_works`, you can just rename it to `_test_feature_works`.



### Under the hood

When processing the extension, the following happens:

- Dryunit checks if it's running from a `*build/*` directory, and returns `()` otherwise.

- Look at the directory where the extension was declared and find all `*.ml` files.

- Extract a structured representation of each file, using OCaml's parser. This is fast, but produce boilerplate files.

- Create a test suite with all module-level functions starting with `"test"`.

- Replace `[%alcotest]` in the AST with the apropriate code to bootstrap Alcotest.



## The future of the project

This project is *framework independent*. It changes the AST, but relies on the user environment to provide and validate the appropriate dependencies. The project itself remains *light*, even if support for new test frameworks supporting similar workflows is added in the future.

This is project is *low maintenance*. Thanks to OCaml's parser and the [Migrate-Parsetree](https://github.com/ocaml-ppx/ocaml-migrate-parsetree) project, this ppx  knows very little about the actual source syntax and already works on all major OCaml versions supporting ppx.

New features like timestamp based caching and configuration for the detection profiles are things to be desired. Maybe even per suite hooks like *before* and *after*, activated explicitly with an extension parameter. Time and user base motivation will tell.



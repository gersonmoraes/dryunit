open Model
open Mod_parser

let check, string, int = Alcotest.(check, string, int)


let len_should_be ?(msg="") ~path expected =
  let len =
    Mods.list_of_path path
    |> List.length in
  check int msg expected len


let test_paths_without_mods () =
  ( len_should_be 0 ~msg:"len zero" ~path:"tests.ml";
    len_should_be 0 ~msg:"false positive" ~path:"async_cancelled_tests.ml";
    len_should_be 0 ~msg:"false positive" ~path:"echain_cancelled_tests.ml";
    len_should_be 0 ~msg:"false positive" ~path:"long_cancelled_tests.ml";
    len_should_be 0 ~msg:"false positive" ~path:"result_cancelled_tests.ml";
  )


let test_requesting_only_async () =
  len_should_be 1 ~path:"async_tests.ml"


let test_requesting_only_result () =
  len_should_be 1 ~path:"result_tests.ml"


let test_requesting_only_echain () =
  len_should_be 1 ~path:"echain_tests.ml"


let test_requesting_only_long () =
  len_should_be 1 ~path:"long_tests.ml"


let tests_requiring_multiple_mods () =
  ( len_should_be 2 ~path:"async_long_tests.ml";
    len_should_be 2 ~path:"echain_result_tests.ml";
    len_should_be 3 ~path:"echain_result_async_tests.ml";
    len_should_be 4 ~path:"echain_long_result_async_tests.ml";
  )

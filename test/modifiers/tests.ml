open Model
open Mod_parser


let len_should_be ?(msg="") ~path expected =
  let len =
    Mods.list_of_path path
    |> List.length in
  Alcotest.(check int) msg expected len


let should_fail ?(msg="") ?(check=fun _ -> true) f : unit =
  let thrown = ref false in
  ( try ignore (f ()) with e ->
      if check e then
        thrown := true
      else raise e
  );
  let msg = "should fail" ^ msg in
  Alcotest.(check bool) msg true (!thrown)


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

let test_echain_and_result_simultaneously_should_fail () =
  should_fail
    ~check:
      ( function
       | Invalid_argument s ->
          Alcotest.(check string "Invalid_argument message")
            "you cannot activate result and echain simultaneously" s;
          true
       | _ -> false
      )
    ( fun () ->
      Mods.of_path "echain_result_async_tests.ml"
    )

open Model



let expected_mods ?(msg="") ~path expected =
  let len =
    Mods_parser.list_of_path path
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
  ( expected_mods 0 ~msg:"len zero" ~path:"tests.ml";
    expected_mods 0 ~msg:"false positive" ~path:"async_cancelled_tests.ml";
    expected_mods 0 ~msg:"false positive" ~path:"long_cancelled_tests.ml";
    expected_mods 0 ~msg:"false positive" ~path:"result_cancelled_tests.ml";
  )


let test_requesting_only_async () =
  expected_mods 1 ~path:"async_tests.ml"


let test_requesting_only_result () =
  expected_mods 1 ~path:"result_tests.ml"



let test_requesting_only_long () =
  expected_mods 1 ~path:"long_tests.ml"


let tests_requiring_multiple_mods () =
  ( expected_mods 2 ~path:"async_long_tests.ml";
    expected_mods 3 ~path:"long_result_async_tests.ml";
  )

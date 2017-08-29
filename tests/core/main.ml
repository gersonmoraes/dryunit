open Ppx_dryunit_runtime

let test_is_substring () =
  let b = Util.is_substring "hello world" "world" in
  Alcotest.(check bool) "is_substring"  true b;
  let b = Util.is_substring "hello world" "disney" in
  Alcotest.(check bool) "not is_substring"  false b


let test_starts_with () =
  let b = Util.starts_with "hello world" "hello" in
  Alcotest.(check bool) "starts_with"  true b;
  let b = Util.starts_with "hello world" "disney" in
  Alcotest.(check bool) "not starts_with"  false b


let test_ends_with () =
  let b = Util.ends_with "hello world" "world" in
  Alcotest.(check bool) "ends_with"  true b;
  let b = Util.ends_with "hello world" "disney" in
  Alcotest.(check bool) "not ends_with"  false b











(* let () = [%alcotest] *)

let test_set = [
  "test_is_substring" , `Quick, test_is_substring;
  "test_starts_with" , `Quick, test_starts_with;
  "test_ends_with" , `Quick, test_ends_with;
]

(* Run it *)
let () =
  Alcotest.run "Ppx_dryunit_runtime.Util tests" [
    "all tests", test_set;
  ]

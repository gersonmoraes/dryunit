
let test_context_present () =
  ignore @@ Unix.getenv "DRYUNIT_CTX"

let test_context_structure () =
  ( let ctx = Unix.getenv "DRYUNIT_CTX" in
    let fields = Str.split (Str.regexp "|") ctx in
    Alcotest.(check int "should have 5 fields") 5 (List.length fields);
    Alcotest.(check string "fqdn") "fqdn=Context_vars_tests.test_context_structure" (List.nth fields 0);
    Alcotest.(check string "suite name") "suite=Context vars" (List.nth fields 1);
    Alcotest.(check string "test name") "name=Context structure" (List.nth fields 2);
    Alcotest.(check string "test loc") "loc=(./context_vars_tests.ml[5,70+4]..[5,70+26])" (List.nth fields 3);
    Alcotest.(check string "test dir") "dir=undefined" (List.nth fields 4);
  )

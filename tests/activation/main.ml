
let test_execution () =
  print_endline "action executed"

let _ =
  [%dryunit_debug_run]

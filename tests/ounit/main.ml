open OUnit2

let () =
  run_test_tt_main (
    "All tests" >::: [
      "Secondary.test_in_secondary" >:: Secondary.test_in_secondary;

      "Tests.test1" >:: Tests.test1;
      "Tests.test2" >:: Tests.test2;

    ]
  )

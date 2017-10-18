
let () =
  Alcotest.run "Main" [
    "Secondary", [
      "test_capit", `Quick, Secondary.test_capit;
      "test_plus", `Quick, Secondary.test_plus;
      "test_capit_another4", `Quick, Secondary.test_capit_another4;
    ];
    "Primary", [
      "test_capit", `Quick, Primary.test_capit;
      "test_plus", `Quick, Primary.test_plus;
      "test_capit_another", `Quick, Primary.test_capit_another;
    ];
  ]

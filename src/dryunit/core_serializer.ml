open Core_runtime
open Printf

open TestSuite
open TestDescription

let boot_alcotest oc suites : unit =
  fprintf oc "let () =\n";
  fprintf oc "  Alcotest.run \"Main\" [\n";
  List.iter
    ( fun suite ->
      fprintf oc "    \"%s\", [\n" suite.suite_name;
      List.iter
        ( fun test ->
          fprintf oc "      \"%s\", `Quick, %s.%s;\n" test.test_name suite.suite_name test.test_name;
        )
        suite.tests;
      fprintf oc "    ];\n";
    )
    suites;
fprintf oc "  ]\n";
flush oc

let boot_ounit oc suites : unit =
  fprintf oc "open OUnit2\n";
  fprintf oc "\nlet () =\n  run_test_tt_main (\n";
  fprintf oc "    \"All tests\" >::: [\n";
  List.iter
    ( fun suite ->
      List.iter
        ( fun test ->
          fprintf oc "      \"%s.%s\" >:: %s.%s;\n" suite.suite_name test.test_name suite.suite_name test.test_name;
        )
        suite.tests;
        fprintf oc "\n";
    )
    suites;
fprintf oc "    ]\n";
fprintf oc "  )\n";
flush oc






let init_extension () =
  print_endline @@ String.trim @@ "
(executables
 ((names (main))
  (libraries (alcotest))
  (preprocess (pps (ppx_dryunit)))))

;; This rule generates the bootstrapping
(rule
 ((targets (main.ml))
  ;;
  ;; Change detection:
  ;;
  (deps ( (glob_files *_tests.ml) (glob_files *_Tests.ml) ))
  ;;
  (action  (with-stdout-to ${@} (run
    dryunit gen --framework alcotest
    ;;
    ;; Uncomment to configure:
    ;;
    ;;  --ignore \"space separated list\"
    ;;  --filter \"space separated list\"
    ;;  --ignore-path \"space separated list\"
  )))))
"

let init_default framework =
  print_endline @@ String.trim @@ "
(executables
 ((names (main))
  (libraries (alcotest))
  (preprocess (pps (ppx_dryunit)))))

;; This rule generates the bootstrapping
(rule
 ((targets (main.ml))
  ;;
  ;; Change detection:
  ;;
  (deps ( (glob_files *_tests.ml) (glob_files *_Tests.ml) ))
  ;;
  (action  (with-stdout-to ${@} (run
    dryunit " ^ TestFramework.to_string framework ^ "
    ;;
    ;; Uncomment to configure:
    ;;
    ;;  --ignore \"space separated list\"
    ;;  --filter \"space separated list\"
    ;;  --ignore-path \"space separated list\"
  )))))
"

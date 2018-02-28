open Printf

open Model
open TestSuite
open TestDescription
open Util

let wrap ~context ~suite ~test =
  let fqdn = sprintf "%s.%s" suite.suite_name test.test_name in
  ( if context then
      sprintf {|
        ( fun v ->
          let () = Unix.putenv "DRYUNIT_CTX" "fqdn=%s|suite=%s|name=%s|loc=%s" in
          %s v
        )|}
        fqdn suite.suite_title test.test_title test.test_loc fqdn
    else
      fqdn
  )

let boot_alcotest ~context oc suites : unit =
  fprintf oc "let () =\n";
  fprintf oc "  Alcotest.run \"Main\" [\n";
  List.iter
    ( fun suite ->
      fprintf oc "    \"%s\", [\n" suite.suite_title;
      List.iter
        ( fun test ->
          fprintf oc "      \"%s\", `Quick, %s;\n"
            test.test_title
            (wrap ~context ~suite ~test);
        )
        suite.tests;
      fprintf oc "    ];\n";
    )
    suites;
fprintf oc "  ]\n";
flush oc


let boot_ounit ~context oc suites : unit =
  fprintf oc "open OUnit2\n";
  fprintf oc "\nlet () =\n  run_test_tt_main (\n";
  fprintf oc "    \"All tests\" >::: [\n";
  List.iter
    ( fun suite ->
      List.iter
        ( fun test ->
          fprintf oc "      \"%s.%s\" >:: %s;\n"
            suite.suite_name
            test.test_name
            (wrap ~context ~suite ~test);
        )
        suite.tests;
        fprintf oc "\n";
    )
    suites;
fprintf oc "    ]\n";
fprintf oc "  )\n";
flush oc


let init_default framework =
  print_endline @@ String.trim @@ "
(executable
 ((name main)
  (libraries (" ^ TestFramework.package framework ^ "))))

(rule
 ((targets (main.ml))
  (deps ( (glob_files {tests.ml,*tests.ml,*Tests.ml}) ))
  (action (with-stdout-to ${@} (run dryunit gen
    --framework " ^ TestFramework.to_string framework ^ "
    ;; --filter \"space separated list\"
    ;; --ignore \"space separated list\"
    ;; --ignore-path \"space separated list\"
  )))))

(alias
  ((name runtest)
   (deps (main.exe))
   (action (run ${<}))
  ))
"

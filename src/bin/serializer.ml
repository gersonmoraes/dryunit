open Printf

open Model
open TestSuite
open TestDescription
open Util

let resolv ~context ~suite ~test =
  let fqdn = sprintf "%s.%s" suite.suite_name test.test_name in
  ( if context then
      sprintf {|
        ( fun v ->
          let () = Unix.putenv "DRYUNIT_CTX" "fqdn=%s|suite=%s|name=%s|loc=%s|path=%s" in
          %s v
        )|}
        fqdn suite.suite_title test.test_title test.test_loc suite.suite_path fqdn
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
            (resolv ~context ~suite ~test);
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
            (resolv ~context ~suite ~test);
        )
        suite.tests;
        fprintf oc "\n";
    )
    suites;
fprintf oc "    ]\n";
fprintf oc "  )\n";
flush oc


let wrapper_from ~activated_mods test =
  let open Model.Modifiers in
  let mods = Model.TestDescription.active_mods ~activated_mods test in
  match mods.async, mods.result with
  | false, false -> "fun"
  | false, true  -> "res"
  | true,  false -> "async"
  | true,  true  -> "async_res"


(**
  Extension api serializer

  The runner parameter should be the name of a module compliant with the
  "Dryunit.Extension_api.Runner" signature
*)
let boot_generic ~context ~runner ~activated_mods oc suites : unit =
  let runner = String.capitalize_ascii runner in
  fprintf oc "let () = \nlet module T = %s in\n" runner;
  fprintf oc "  let module T = %s in\n" runner;
  fprintf oc "  T.run [\n";
  List.iter
    ( fun suite ->
      fprintf oc
{|  ( let ctx =
      T.suite_ctx ~name:"%s" ~title:"%s" ~path:"%s" in
    T.suite ~ctx ~tests:[
|}
      suite.suite_name suite.suite_title suite.suite_path;
      List.iter
        ( fun test ->
          fprintf oc
{| T.test "%s" ~ctx
    ~name:"%s"
    ~f:(T.wrap_%s %s)
    ~loc:"%s";
|}
            test.test_title
            (wrapper_from ~activated_mods test)
            test.test_name
            (resolv ~context ~suite ~test)
            test.test_loc;
        )
        suite.tests;
        fprintf oc "  ]);\n";
    )
    suites;
  fprintf oc "  ]\n";
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

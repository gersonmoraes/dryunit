#if OCAML_VERSION < (4, 03, 0)
#define Pconst_string Const_string
#define OCaml_OMP OCaml_402
#elif OCAML_VERSION < (4, 04, 0)
#define OCaml_OMP OCaml_403
#elif OCAML_VERSION < (4, 05, 0)
#define OCaml_OMP OCaml_404
#elif OCAML_VERSION < (4, 06, 0)
#define OCaml_OMP OCaml_405
#elif OCAML_VERSION < (4, 07, 0)
#define OCaml_OMP OCaml_406
#endif


open Migrate_parsetree
open OCaml_OMP.Ast
open Parsetree
open Ast_convenience
open Ast_helper
open Dryunit_core


let bootstrap_alcotest suites =
  suites |>
  List.map
  ( fun suite ->
    suite.tests |>
    List.map
    ( fun t ->
      tuple
      [ str t.test_title
      ; Exp.variant "Quick" None
      ; evar t.test_name
      ]
    ) |>
    ( fun test_set ->
      tuple [ str suite.suite_title; list test_set ]
    )
  ) |>
  ( fun pairs ->
    app (evar "Alcotest.run") [ str "Default"; list pairs ]
  )



(* let bootstrap_ounit suite =
  let test_set =
    suite.tests |>
    List.map
     ( fun t ->
       app (evar ">::") [ str t.test_name; evar t.test_name ]
     ) in
   let set_list = list test_set in
   app (evar "OUnit2.run_test_tt_main") [ app (evar ">:::") [str suite.suite_name; set_list] ] *)


let bootstrap_ounit suites =
  let () = Printf.printf "bootstrapping ounit from \n - dir: %s\n - filename: %s\n"
    (Sys.getcwd ())
    !(Location.input_name) in
  suites |>
  List.map
  ( fun suite ->
    suite.tests |>
    List.map
    ( fun t ->
      app (evar ">::") [ str (suite.suite_title ^ "." ^ t.test_name); evar t.test_name ]
    )
  ) |>
  List.flatten |>
  ( fun tests ->
    app (evar "OUnit2.run_test_tt_main") [ app (evar ">:::") [str "Default"; list tests] ]
  )


let rewriter _config _cookies =
  let super = Ast_mapper.default_mapper in
  if not (in_build_dir ()) then
    { super with expr = fun _ _ -> unit () }
  else
  let expr self e =
    match e.pexp_desc with
    (* debug just returns a string with detected tests *)
    | Pexp_extension ({ txt = "dryunit_debug"; _ }, PStr []) ->
      let output = Dryunit_core.debug ~filename:!Location.input_name in
      { e with pexp_desc = Pexp_constant (Pconst_string (output, None)) }

    (* alcotest *)
    | Pexp_extension ({ txt = "alcotest"; _ }, PStr []) ->
      bootstrap_alcotest (detect_suites ~filename:!Location.input_name)

    (* ounit *)
    | Pexp_extension ({ txt = "ounit"; _ }, PStr []) ->
      bootstrap_ounit (detect_suites ~filename:!Location.input_name)

    (* anything else *)
    | _ -> super.expr self e
  in
  { super with expr }

let () =
  Driver.register ~name:"ppx_dryunit"
    (module OCaml_OMP)
    rewriter

(* Rewrite [%fourty_two] as 42 *)

open Migrate_parsetree
open OCaml_404.Ast
open Parsetree
open Ast_helper
open Ast_convenience

let rewriter _config _cookies =
  let super = Ast_mapper.default_mapper in
  let expr self e =
    match e.pexp_desc with

    (* dryunit *)
    | Pexp_extension ({ txt = "dryunit"; _ }, PStr []) ->
      { e with pexp_desc = Pexp_constant (Pconst_string ("Hello World", None)) }

    (* dryunit_debug *)
    | Pexp_extension ({ txt = "dryunit_debug"; _ }, PStr []) ->
      let output = Dryunit_core.debug ~filename:!Location.input_name in
      { e with pexp_desc = Pexp_constant (Pconst_string (output, None)) }

    (* dryunit_debug_run *)
    (* | Pexp_extension ({ txt = "dryunit_debug_run"; _ }, PStr []) ->
      let open Dryunit_core in
      let tests = extract_from ~filename:!Location.input_name in
      (* { e with pexp_desc = apply_unit (List.hd tests).test_name } *)
      let test_name = (List.hd tests).test_name in
      app (evar test_name) [unit ()] *)

    (* dryunit_debug_run *)
    | Pexp_extension ({ txt = "dryunit_alcotest"; _ }, PStr []) ->
      let open Dryunit_core in
      let test_set =
        extract_from ~filename:!Location.input_name
        |>  List.map (fun t -> tuple [ str t.test_title; Exp.variant "Quick" None; evar t.test_name ])
        |> list
       in
       let test_set_list = list [ tuple [ str "test_set"; test_set ] ] in
       app (evar "Alcotest.run") [ str "My first test"; test_set_list ]

    (* anything else *)
    | _ -> super.expr self e

  in
  { super with expr }

let () =
  Driver.register ~name:"ppx_dryunit"
    (module OCaml_404)
    rewriter

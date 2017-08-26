(* Rewrite [%fourty_two] as 42 *)

open Migrate_parsetree
open OCaml_404.Ast
open Parsetree
open Ast_helper
open Ast_convenience


let apply_unit ~e test_name =
  let loc = e.pexp_loc in
  Pexp_apply ({e with pexp_desc = Pexp_ident {txt = Lident test_name; loc}},
  [(Nolabel, {e with pexp_desc = Pexp_construct ({txt = Lident "()"; loc}, None)})])



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
    | Pexp_extension ({ txt = "dryunit_debug_run"; _ }, PStr []) ->
      let open Dryunit_core in
      let tests = extract_from ~filename:!Location.input_name in
      { e with pexp_desc = apply_unit ~e (List.hd tests).test_name }

    (* anything else *)
    | _ -> super.expr self e

  in
  { super with expr }

let () =
  Driver.register ~name:"ppx_dryunit"
    (module OCaml_404)
    rewriter

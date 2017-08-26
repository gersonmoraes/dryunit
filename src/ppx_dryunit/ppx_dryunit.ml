(* Rewrite [%fourty_two] as 42 *)

open Migrate_parsetree
open OCaml_404.Ast
open Parsetree

open Dryunit_core.Parser

let rewriter _config _cookies =
  let super = Ast_mapper.default_mapper in
  let expr self e =
    match e.pexp_desc with

    (* sample *)
    | Pexp_extension ({ txt = "sample_hook"; _ }, PStr []) ->
      { e with pexp_desc = Pexp_constant (Pconst_integer ("42", None)) }

    (* dryunit *)
    | Pexp_extension ({ txt = "dryunit"; _ }, PStr []) ->
      { e with pexp_desc = Pexp_constant (Pconst_string ("Hello World", None)) }

    (* dryunit_debug *)
    | Pexp_extension ({ txt = "dryunit_debug"; _ }, PStr []) ->
      let _data = extract_from ~name:"Dryunit debug" ~filename:!Location.input_name in
      let output = "Hello World" in
      { e with pexp_desc = Pexp_constant (Pconst_string (output, None)) }

    (* anything else *)
    | _ -> super.expr self e

  in
  { super with expr }

let () =
  Driver.register ~name:"ppx_dryunit"
    (module OCaml_404)
    rewriter

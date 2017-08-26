(* Rewrite [%fourty_two] as 42 *)

open Migrate_parsetree
open OCaml_404.Ast
open Parsetree

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

    (* anything else *)
    | _ -> super.expr self e

  in
  { super with expr }

let () =
  Driver.register ~name:"ppx_dryunit"
    (module OCaml_404)
    rewriter

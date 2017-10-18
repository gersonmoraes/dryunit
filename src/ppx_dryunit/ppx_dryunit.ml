#if OCAML_VERSION < (4, 03, 0)
#define Pconst_string Const_string
#define OCaml_OMP OCaml_402
#define Ast_OMP Ast_402
#define Ppx_tools_OMP Ppx_tools_402
#elif OCAML_VERSION < (4, 04, 0)
#define OCaml_OMP OCaml_403
#define Ast_OMP Ast_403
#define Ppx_tools_OMP Ppx_tools_403
#elif OCAML_VERSION < (4, 05, 0)
#define OCaml_OMP OCaml_404
#define Ast_OMP Ast_404
#define Ppx_tools_OMP Ppx_tools_404
#elif OCAML_VERSION < (4, 06, 0)
#define OCaml_OMP OCaml_405
#define Ast_OMP Ast_405
#define Ppx_tools_OMP Ppx_tools_405
#elif OCAML_VERSION < (4, 07, 0)
#define OCaml_OMP OCaml_406
#define Ast_OMP Ast_406
#define Ppx_tools_OMP Ppx_tools_406
#endif


module Core_capitalize = struct
#if OCAML_VERSION < (4, 03, 0)
  let capitalize_ascii = String.capitalize
#else
  let capitalize_ascii = String.capitalize_ascii
#endif
end

module Ppx_dryunit_runtime = struct

(* ============================| SHARED CODE |============================ *)
module Core_util = struct
#include "../dryunit/core_util.ml"
end
#include "../dryunit/core_runtime.ml"

(* ============================| EXT ONLY |============================ *)
  let throw ~loc msg =
    raise (Location.Error (Location.error ~loc msg))

  type record_fields = (Longident.t Asttypes.loc *  Parsetree.expression) list

  let validate_params ~loc (current: record_fields) expected_fields =
    let param n =
      ( match fst @@ List.nth current n with
        | {txt = Lident current} -> current
        | _ -> throw ~loc ("Unexpected structure")
      ) in
    let check_param n expected =
      let current =
        ( try param n with
          | _ -> throw ~loc ("Missing configuration: " ^ expected)
        ) in
      if not (current = expected) then
        throw ~loc (format "I was expecting `%s`, but found `%s`." expected current)
    in
    List.iteri
      ( fun i name ->
        check_param i name
      )
      expected_fields;
    let expected_len = List.length expected_fields in
    if List.length current > expected_len then
      throw ~loc (format "Unknown configuration field: `%s`." (param expected_len))
end

open Migrate_parsetree
open OCaml_OMP.Ast
open Parsetree

open Ast_OMP
open Ppx_tools_OMP
open Ast_convenience

open Ast_helper
open Ppx_dryunit_runtime
open Ppx_dryunit_runtime.Core_util

open TestSuite
open TestDescription

let bootstrap_alcotest suites =
  suites |>
  List.map
  ( fun suite ->
    let current_module = (suite.suite_path = !Location.input_name) in
    suite.tests |>
    List.map
    ( fun t ->
      tuple
      [ str t.test_title
      ; Exp.variant "Quick" None
      ; evar (test_name ~current_module suite t)
      ]
    ) |>
    ( fun test_set ->
      tuple [ str suite.suite_title; list test_set ]
    )
  ) |>
  ( fun pairs ->
    app (evar "Alcotest.run") [ str "Default"; list pairs ]
  )


let bootstrap_ounit suites =
  suites |>
  List.map
  ( fun suite ->
    let current_module = (suite.suite_path = !Location.input_name) in
    suite.tests |>
    List.map
    ( fun t ->
      app (evar "OUnit2.>::") [ str (suite.suite_title ^ "." ^ t.test_name);
        evar (test_name ~current_module suite t) ]
    )
  ) |>
  List.flatten |>
  ( fun tests ->
    app (evar "OUnit2.run_test_tt_main") [ app (evar "OUnit2.>:::") [str "Default"; list tests] ]
  )


let boot ~loc ~cache_dir ~cache_active ~framework ~ignore ~filter ~detection ~ignore_path =
  let throw = throw ~loc in
  let f =
    ( match framework with
      | "alcotest" -> bootstrap_alcotest
      | "ounit" -> bootstrap_ounit
      | _ -> throw (format "Test framework not recognized: `%s`" framework)
    ) in
  let custom_dir =
    if (cache_dir = ".dryunit") || (cache_dir = "_build/.dryunit") then None
    else
    ( if Core_util.starts_with cache_dir Filename.dir_sep then
        let () = mkdir_p cache_dir in
        Some cache_dir
      else
        throw ("Cache directory must be \".dryunit\" or a full custom path. Current value is `" ^ cache_dir ^ "`");
    ) in
  let ignore = filter_from ~throw ~name:"ignore" ignore in
  let filter = filter_from ~throw ~name:"filter" filter in
  let ignore_path = filter_from ~throw ~name:"ignore_path" ignore_path in
  let suites =
    let filename = !Location.input_name in
    ( match detection with
      | "dir" -> detect_suites ~filename ~custom_dir ~cache_active ~ignore_path
      | "file" -> [ suite_from ~dir:(Filename.dirname filename) (Filename.basename filename) ]
      | _ -> throw "The field `detection` only accepts \"dir\" or \"file\"."
    ) in
  validate_filters ~throw ~ignore ~filter;
  f (apply_filters ~filter ~ignore suites)




let rewriter _config _cookies =
  let super = Ast_mapper.default_mapper in
  if not (in_build_dir ()) then
    { super with expr = fun _ _ -> unit () }
  else
  let expr self e =
    match e.pexp_desc with
    (* debug just returns a string with detected tests *)
    | Pexp_extension ({ txt = "dryunit_debug"; _ }, PStr []) ->
      let output = Ppx_dryunit_runtime.print_tests_from ~filename:!Location.input_name in
      { e with pexp_desc = Pexp_constant (Pconst_string (output, None)) }

    (* debug just returns a string with detected tests *)
    | Pexp_extension ({ txt = "dryunit_debug2"; _ }, PStr []) ->
      app (evar "Printf.printf") [str "%s %s"; str "Hello"; str "World!" ]

    (* alcotest *)
    (* | Pexp_extension ({ txt = "alcotest"; _ }, PStr []) ->
      bootstrap_alcotest (detect_suites ~filename:!Location.input_name
        ~custom_dir:None ~cache_active:true) *)

    (* ounit *)
    (* | Pexp_extension ({ txt = "ounit"; _ }, PStr []) ->
      bootstrap_ounit (detect_suites ~filename:!Location.input_name
        ~custom_dir:None ~cache_active:true) *)

    (* new-interface *)
    | Pexp_extension ({ txt = "dryunit"; _ },
        PStr [ {pstr_desc = (Pstr_eval ({pexp_desc = Pexp_record (configs, None);
          pexp_loc; _}, attr)); _} ]) ->
        ( match configs with
          | [({txt = Lident "cache_dir"},
              {pexp_desc = Pexp_constant (Pconst_string (cache_dir, None))});
             ({txt = Lident "cache"},
              {pexp_desc = Pexp_construct ({txt = Lident cache}, None)});
             ({txt = Lident "framework"},
              {pexp_desc = Pexp_constant (Pconst_string (framework, None))});
             ({txt = Lident "ignore"},
              {pexp_desc = Pexp_constant (Pconst_string (ignore, None))});
             ({txt = Lident "filter"},
              {pexp_desc = Pexp_constant (Pconst_string (filter, None))});
             ({txt = Lident "detection"},
              {pexp_desc = Pexp_constant (Pconst_string (detection, None))});
             ({txt = Lident "ignore_path"},
              {pexp_desc = Pexp_constant (Pconst_string (ignore_path, None))})]
            when cache = "true" || cache = "false" ->
              let cache_active = (cache = "true") in
              boot ~loc:e.pexp_loc ~cache_dir ~cache_active ~framework ~ignore
                ~filter ~detection ~ignore_path
         | _ ->
          validate_params ~loc:e.pexp_loc configs
            ["cache_dir"; "cache"; "framework"; "ignore"; "filter"; "detection"; "ignore_path" ];
          throw ~loc:e.pexp_loc "Configuration for ppx_dryunit is invalid."
        )
    | Pexp_extension ({ txt = "dryunit"; _ }, _ ) ->
        throw ~loc:e.pexp_loc "Dryunit configuration should defined as a record."

    (* anything else *)
    | _ -> super.expr self e
  in
  { super with expr }

let () =
  Driver.register ~name:"ppx_dryunit"
    (module OCaml_OMP)
    rewriter

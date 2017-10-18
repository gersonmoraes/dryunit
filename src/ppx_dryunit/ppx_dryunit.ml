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


module Capitalize = struct
#if OCAML_VERSION < (4, 03, 0)
  let capitalize_ascii = String.capitalize
#else
  let capitalize_ascii = String.capitalize_ascii
#endif
end

module Ppx_dryunit_runtime = struct
module Core_util = struct
#include "../dryunit/core_util.ml"
end

#include "../dryunit/core_runtime.ml"
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

let mkdir_p dir =
  split sep dir |>
  List.fold_left
  ( fun acc basename ->
    let path = acc ^ sep ^ basename in
    if not (Sys.file_exists path) then
      Unix.mkdir path 0o755;
    path
  )
  "" |>
  ignore


let filter_from ~loc ~name value : string list =
  let l = split " " value in
  List.iter
    ( fun v ->
      if String.length v < 4 then
        throw ~loc (format "Each word in the field `%s` must be at least 3 chars long" name);
      if v = "test" then
        throw ~loc (format "You are not allowed to use the word `test` in the field `%s`" name)
    )
    l;
  l


let should_ignore ~ignore name =
  match ignore with
  | [] -> assert false
  | _ -> List.exists (fun v -> Core_util.is_substring name v) ignore

let should_filter ~filter name =
  match filter with
  | [] -> assert false
  | _ -> List.exists (fun v -> Core_util.is_substring name v) filter


let apply_filters ~loc ~filter ~ignore suites =
  let filter_tests tests =
    ( if List.length ignore == 0 then tests
      else
        List.filter (fun test -> not (should_ignore ~ignore test.test_name)) tests
    ) |>
    fun tests ->
    ( if List.length filter == 0 then tests
      else
        List.filter (fun test -> should_filter ~filter test.test_name) tests
    )
  in
  ( List.fold_left
      ( fun acc suite ->
        match filter_tests suite.tests with
        | [] -> acc
        | active_tests -> { suite with tests = active_tests } :: acc
      )
      []
      suites
  )

let validate_filters ~loc ~ignore ~filter =
  match ignore, filter with
  | [], [] -> ()
  | _v, [] -> ()
  | [], _v -> ()
  | _ ->
    List.iter
      ( fun v_filter ->
        if List.exists (fun v -> v_filter = v) ignore then
          throw ~loc (format "Query `%s` appears in the fields `filter` and `ignore`." v_filter)
      )
      filter


let boot ~loc ~cache_dir ~cache_active ~framework ~ignore ~filter ~detection ~ignore_path =
  let f =
    ( match framework with
      | "alcotest" -> bootstrap_alcotest
      | "ounit" -> bootstrap_ounit
      | _ -> throw ~loc (format "Test framework not recognized: `%s`" framework)
    ) in
  let custom_dir =
    if (cache_dir = ".dryunit") || (cache_dir = "_build/.dryunit") then None
    else
    ( if Core_util.starts_with cache_dir Filename.dir_sep then
        let () = mkdir_p cache_dir in
        Some cache_dir
      else
        throw ~loc ("Cache directory must be \".dryunit\" or a full custom path. Current value is `" ^ cache_dir ^ "`");
    ) in
  let ignore = filter_from ~loc ~name:"ignore" ignore in
  let filter = filter_from ~loc ~name:"filter" filter in
  let ignore_path = filter_from ~loc ~name:"ignore_path" ignore_path in
  let suites =
    let filename = !Location.input_name in
    ( match detection with
      | "dir" -> detect_suites ~filename ~custom_dir ~cache_active ~ignore_path
      | "file" -> [ suite_from ~dir:(Filename.dirname filename) (Filename.basename filename) ]
      | _ -> throw ~loc "The field `detection` only accepts \"dir\" or \"file\"."
    ) in
  validate_filters ~loc ~ignore ~filter;
  f (apply_filters ~loc ~filter ~ignore suites)


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

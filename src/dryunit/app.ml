(*
  Our cmd-free app definitions and models
*)

open Core_util
open Printf
open Core_runtime

let mkdir_p dir =
  split Filename.dir_sep dir |>
  List.fold_left
  ( fun acc basename ->
    let path = acc ^ Filename.dir_sep ^ basename in
    if not (Sys.file_exists path) then
      Unix.mkdir path 0o755;
    path
  )
  "" |>
  ignore

let gen_extension ~nocache ~framework ~cache_dir ~ignore ~filter ~targets ~ignore_path =
  let _ = TestFramework.of_string framework in
  let detection = "dir" in
  let get_int () =
    (Random.int 9999) + 1 in
  let msg = "This file is supposed to be generated before build with a random ID." in
  let id = sprintf "%d%d%d" (get_int ()) (get_int ()) (get_int ()) in
  ( sprintf "(*\n  %s\n  ID = %s\n*)\nlet () =\n  [%%dryunit\n    { cache_dir   = \"%s\"\n    ; cache       = %s\n    ; framework   = \"%s\"\n    ; ignore      = \"%s\"\n    ; filter      = \"%s\"\n    ; detection   = \"%s\"\n    ; ignore_path = \"%s\"\n    }\n  ]\n"
      msg id cache_dir (string_of_bool @@ not nocache) framework ignore filter detection ignore_path
  ) |>
  fun output ->
  if List.length targets == 0 then
    print_endline output
  else
    ( List.iter
      ( fun target ->
        let path = Sys.getcwd () ^ Filename.dir_sep ^ target in
        let dir = Filename.dirname path in
        if not (Sys.file_exists dir) then
          mkdir_p dir;
        let oc = open_out path in
        Printf.fprintf oc "%s" output;
        close_out oc
      )
      targets
    )


let init () =
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


let clean () =
  let dir = ".dryunit" in
  if Sys.file_exists dir && Sys.is_directory dir then
  ( Array.iter
      ( fun v -> Unix.unlink (dir ^ Filename.dir_sep ^ v) )
      ( Sys.readdir dir );
    Unix.rmdir dir
  )

let throw s =
  Printf.eprintf "%s\n" s;
  exit 1


let get_suites ~nocache ~framework ~cache_dir ~ignore ~filter ~targets ~ignore_path ~detection ~main =
  let _f =
    ( match framework with
      | TestFramework.Alcotest -> ignore
      | TestFramework.OUnit -> ignore
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
  validate_filters ~throw ~ignore ~filter;
  let filename = main in
  ( match detection with
    | "dir" -> detect_suites ~filename ~custom_dir ~cache_active:true ~ignore_path
    | "file" -> [ suite_from ~dir:(Filename.dirname filename) (Filename.basename filename) ]
    | _ -> throw "The field `detection` only accepts \"dir\" or \"file\"."
  )
  |> apply_filters ~filter ~ignore


let gen_executable () =
  ""

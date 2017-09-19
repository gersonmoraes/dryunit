(*
  Our cmd-free app definitions and models
*)

open Util
open Config
open Types

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

let gen ~nocache ~framework ~cache_dir ~ignore ~filter ~targets =
  let detection = "dir" in
  let get_int () =
    (Random.int 9999) + 1 in
  let msg = "This file is supposed to be generated before build with a random ID." in
  let id = format "%d%d%d" (get_int ()) (get_int ()) (get_int ()) in
  ( format "(*\n  %s\n  ID = %s\n*)\nlet () =\n  [%%dryunit\n    {\n    ; cache_dir = %s\n    ; cache     = %s\n    ; framework = \"%s\"\n    ; ignore    = \"%s\"\n    ; filter    = \"%s\"\n    ; detection = \"%s\"\n    }\n  ]\n"
    msg id cache_dir (string_of_bool @@ not nocache) framework ignore filter detection
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



let build () =
  let filename =
    if Sys.file_exists "files/dryunit.toml" then
      "files/dryunit.toml"
    else
    ( if Sys.file_exists "dryunit.toml" then
        "dryunit.toml"
      else
        failwith "Configuration file not found. Try `dryunit init`."
    ) in
  let project = Config.parse ~filename in
  let open Types in
  let
    { meta =
      { name
      ; description
      ; framework
      ; profile
      }
    ; cache
    ; detection =
      { watch
      ; filter
      ; main
      ; targets
      }
    ; ignore
    } = project in
  let cache_dir = cache.dir in
  let framework = string_of_framework framework in
  let ignore = String.concat " " ignore.query in
  let nocache = not cache.active in
  gen ~nocache ~framework ~cache_dir ~ignore ~filter ~targets

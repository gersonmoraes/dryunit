(*
  Our cmd-free app definitions and models
*)

open Util
open Config
open Types

let gen ~nocache ~framework ~cache_dir ~ignore ~filter ~targets =
  let detection = "dir" in
  let get_int () =
    (Random.int 9999) + 1 in
  let msg = "This file is supposed to be generated before build with a random ID." in
  let id = format "%d%d%d" (get_int ()) (get_int ()) (get_int ()) in
  ( format "(*\n  %s\n  ID = %s\n*)\nlet () =\n  [%%dryunit \n    {\n    ; cache_dir = %s\n    ; cache     = %s\n    ; framework = \"%s\"\n    ; ignore    = \"%s\"\n    ; filter    = \"%s\"\n    ; detection = \"%s\"\n    }\n  ]"
    msg id cache_dir (string_of_bool @@ not nocache) framework ignore filter detection
  )
  |> print_endline

open Util
open Util.Config
open Types

let noop = { meta = None;  cache = None; detection = None; ignore = None }

let framework_from = function
  | "alcotest" -> Alcotest
  | "ounit" -> OUnit
  | other -> failwith @@ "invalid framework: " ^ other

let profile_from = function
  | "jbuilder" -> Jbuilder
  | "custom" -> Custom
  | other -> failwith @@ "invalid building profile: " ^ other


let parse ~filename : project =
  let toml = Toml.Parser.(from_filename filename |> unsafe) in
  let meta_t = get_table "meta" toml in
  let cache_t = get_table "cache" toml in
  let detection_t = get_table "detection" toml in
  let ignore_t = get_table "ignore" toml in
  { meta = Some
    { name        = get_string "name" meta_t
    ; description = get_string_opt "description" meta_t
    ; framework   = framework_from @@ get_string "framework" meta_t
    ; profile     = profile_from @@ get_string "profile" meta_t
    }
  ; cache = Some
    { active = get_bool "active" cache_t
    ; dir    = get_string "dir" cache_t
    }
  ; detection = Some
    { watch   = get_string_array_opt "watch" detection_t
    ; main    = get_string "main" detection_t
    ; targets = get_string_array_opt "targets" detection_t
    }
  ; ignore = Some
    { directories = get_string_array "directories" ignore_t
    ; query       = get_string_array "query" ignore_t
    }
  }

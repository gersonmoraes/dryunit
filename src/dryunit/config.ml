open Util
open Util.Config_helpers
open Types

(* let noop = { meta = None;  cache = None; detection = None; ignore = None } *)

let framework_from = function
  | "alcotest" -> Alcotest
  | "ounit" -> OUnit
  | other -> failwith @@ "invalid framework: " ^ other


let profile_from = function
  | "jbuilder" -> Jbuilder
  | "custom" -> Custom
  | other -> failwith @@ "invalid building profile: " ^ other


let default = { meta =
  { name = "My Project"
  ; framework = Alcotest
  ; profile = Custom
  }
; cache =
  { active = true
  ; dir = ".dryunit"
  }
; detection =
  { watch = Some []
  ; filter = ""
  ; main = ""
  ; targets = []
  }
; ignore =
  { directories = []
  ; query = []
  }
}

let parse ~filename : project =
  let toml = Toml.Parser.(from_filename filename |> unsafe) in
  let meta_t = get_table "meta" toml in
  let cache_t = get_table "cache" toml in
  let detection_t = get_table "detection" toml in
  let ignore_t = get_table "ignore" toml in
  { meta =
    { name        = get_string "name" meta_t
    ; framework   = framework_from @@ get_string "framework" meta_t
    ; profile     = profile_from @@ get_string "profile" meta_t
    }
  ; cache =
    { active = get_bool "active" cache_t
    ; dir    = get_string "dir" cache_t
    }
  ; detection =
    { watch   = get_string_array_opt "watch" detection_t
    ; filter  = get_string "filter" detection_t
    ; main    = get_string "main" detection_t
    ; targets = get_string_array "targets" detection_t
    }
  ; ignore =
    { directories = get_string_array "directories" ignore_t
    ; query       = get_string_array "query" ignore_t
    }
  }

let export project =
  let open TomlTypes in
  Printf.printf "# Some information to get you started.\n\n%!";
  let print_table name values =
    Printf.printf "[%s]\n%s\n"name (Toml.Printer.string_of_table values) in
  print_table "meta"
    ( Toml.of_key_values
      [ Toml.key "name", TString project.meta.name
      ; Toml.key "framework", TString (string_of_framework project.meta.framework)
      ; Toml.key "profile", TString (string_of_profile project.meta.profile)
      ]
    );
    print_table "meta"
      ( Toml.of_key_values
        [ Toml.key "active", TBool project.cache.active
        ; Toml.key "dir", TString project.cache.dir
        ]
      );
    print_table "detection"
      ( Toml.of_key_values
        [ Toml.key "watch", TArray (NodeString (unwrap_or [] project.detection.watch))
        ; Toml.key "dir", TString project.detection.filter
        ; Toml.key "main", TString project.detection.main
        ]
      );
    print_table "ignore"
      ( Toml.of_key_values
        [ Toml.key "directories", TArray (NodeString (project.ignore.directories))
        ; Toml.key "query", TArray (NodeString project.ignore.query)
        ]
      );

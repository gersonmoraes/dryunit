

module Modifiers = struct
  type t =
    | Async_mod
    | Long_mod
    | Result_mod
    | Option_mod

  type activated =
    { async  : bool
    ; long   : bool
    ; result : bool
    ; opt    : bool
    }

  let of_string = function
    | "async"  -> Some Async_mod
    | "lwt"    -> Some Async_mod
    | "long"   -> Some Long_mod
    | "result" -> Some Result_mod
    | "opt"    -> Some Option_mod
    | "option" -> Some Option_mod
    | other    -> None

  let to_string = function
    | Async_mod  -> "async"
    | Long_mod   -> "long"
    | Result_mod -> "result"
    | Option_mod -> "opt"
end


module TestDescription = struct
  type t =
    { test_name  : string
    ; test_title : string
    ; test_loc   : string
    ; test_mods  : Modifiers.activated
    }

  let active_mods ~activated_mods:a { test_mods = m }  =
    Modifiers.(
    { async  = a.async  && m.async
    ; result = a.result && m.result
    ; long   = a.long   && m.long
    ; opt    = a.opt    && m.opt
    })
end


module TestSuite = struct
  type t =
    { suite_title     : string
    ; suite_name      : string
    ; suite_full_path : string
    ; suite_path      : string
    ; timestamp       : float
    ; tests           : TestDescription.t list
    }
end


module TestFramework = struct
  type t = Alcotest | OUnit | ExtensionApi of { runner : string }

  let of_string = function
    | "alcotest" -> Alcotest
    | "ounit" -> OUnit
    | other -> raise (Invalid_argument ("Not supported test framework: " ^ other))

  let to_string = function
    | Alcotest -> "alcotest"
    | OUnit -> "ounit"
    | ExtensionApi { runner } -> runner

  let package = function
    | Alcotest -> "alcotest"
    | OUnit -> "oUnit"
    | ExtensionApi _ -> ""
end

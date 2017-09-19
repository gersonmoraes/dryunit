(* Supported frameworks *)
type framework = Alcotest | OUnit

let string_of_framework = function
  | Alcotest -> "alcotest"
  | OUnit -> "ounit"

(* Bulding profiles *)
type profile = Jbuilder | Custom

let string_of_profile = function
  | Jbuilder -> "jbuilder"
  | Custom -> "custom"

type meta =
  { name: string
  ; profile: profile
  ; framework: framework
  }

type cache =
  { active: bool
  ; dir: string
  }

type detection =
  { watch: (string list) option
  ; main: string
  ; targets: string list
  ; filter: string
  }

type ignore =
  { directories: string list
  ; query: string list
  }

(* A manageable project *)
type project =
  { meta: meta
  ; cache: cache
  ; detection: detection
  ; ignore: ignore
  }

(* Supported frameworks *)
type framework = Alcotest | OUnit

(* Bulding profiles *)
type profile = Jbuilder | Custom

type meta =
  { name: string
  ; description: string option
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
  ; targets: (string list) option
  }

type ignore =
  { directories: string list
  ; query: string list
  }

(* A manageable project *)
type project =
  { meta: meta option
  ; cache: cache option
  ; detection: detection option
  ; ignore: ignore option
  }

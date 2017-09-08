
module Util : sig
  val is_substring: string -> string -> bool
  val starts_with: string -> string -> bool
  val ends_with: string -> string -> bool
end

type test = {
  test_name: string;
  test_title: string;
}

type testsuite = {
  suite_title: string;
  suite_name: string;
  suite_path: string;
  timestamp: float;
  tests: test list;
}

val in_build_dir: unit -> bool

val debug: filename:string -> string
val detect_suites: filename:string -> testsuite list

val test_name:  current_module:bool -> testsuite -> test -> string

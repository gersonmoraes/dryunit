
type test = {
  test_name: string;
  test_title: string;
}

type testsuite = {
  suite_title: string;
  suite_name: string;
  (* suite_path: string; *)
  tests: test list;
}

val in_build_dir: unit -> bool

val debug: filename:string -> string
val detect_suites: filename:string -> testsuite list

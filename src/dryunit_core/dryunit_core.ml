open Util
open Printf

module Util = Util

#if OCAML_VERSION < (4, 03, 0)
  let capitalize_ascii = String.capitalize
#else
  let capitalize_ascii = String.capitalize_ascii
#endif


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

let title_from v = capitalize_ascii @@ title_from v
let title_from_no_padding v = capitalize_ascii @@ title_from_filename v

let in_build_dir () =
  is_substring (Sys.getcwd ()) "build/"

let extract_from ~filename : test list =
  tests_from filename
  |> List.map
    (fun test_name ->
        let () = Printf.printf "  (found: %s)\n" test_name in
       { test_name; test_title = title_from test_name }
    )

let suite_from ~dir filename : testsuite =
  let () = Printf.printf "checking %s [dir = %s]\n" dir filename in
  let name = (Filename.basename filename) in
  { suite_name = name;
    suite_title = title_from_no_padding (Filename.chop_suffix name ".ml");
    (* suite_path = filename; *)
    tests = extract_from ~filename:(sprintf "%s%s%s" dir Filename.dir_sep name)
  }

let detect_suites ~filename : testsuite list =
  let dir = Filename.dirname filename in
  Sys.readdir dir
  |> Array.to_list
  |> List.filter
     ( fun v ->
        let basename = Filename.basename v in
        let len = String.length basename in
        (ends_with v ".ml") && (Bytes.index basename '.' == (len - 3))
     )
  |> List.map (suite_from ~dir)

let pp name tests =
  print_endline ("Tests in `" ^ name ^ "`");
  List.iter (fun t -> Printf.printf " - %s [%s]\n" t.test_title t.test_name) tests

let debug ~filename : string =
  let tests = ref [] in
  let _ : unit =
    detect_suites ~filename
    |> List.iter
       ( fun suite ->
         tests := suite.tests @ !tests
      )
  in
  String.concat "\n" (List.map (fun test -> test.test_title) !tests)


module Test = struct
  let name (t:test) = t.test_name
  let title (t:test) = t.test_title
end

let extract_name_from_file ~filename =
  capitalize_ascii

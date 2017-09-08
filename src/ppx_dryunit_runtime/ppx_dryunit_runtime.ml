open Util
open Printf

module Util = Util

#if OCAML_VERSION < (4, 03, 0)
  let capitalize_ascii = String.capitalize
#else
  let capitalize_ascii = String.capitalize_ascii
#endif

let sep = Filename.dir_sep

type test = {
  test_name: string;
  test_title: string;
}

type testsuite = {
  suite_title: string;
  suite_name: string;
  (* module_name: string; *)
  suite_path: string;
  timestamp: float;
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
       { test_name; test_title = title_from test_name }
    )

let suite_from ~dir filename : testsuite =
  let () = Printf.printf ">> Analysing %s\n" filename in
  let name = (Filename.basename filename) in
  { suite_name = capitalize_ascii (Filename.chop_suffix name ".ml");
    suite_title = title_from_no_padding (Filename.chop_suffix name ".ml");
    suite_path = filename;
    timestamp = Unix.((stat (dir ^ sep ^ filename)).st_mtime);
    tests = extract_from ~filename:(sprintf "%s%s%s" dir sep name)
  }

let test_name ~current_module suite test =
  if current_module then
    test.test_name
  else
    (suite.suite_name ^ "." ^ test.test_name)

let cache_dir () =
  let flag_ref = ref false in
    Str.split (Str.regexp sep) (Sys.getcwd ()) |>
    List.rev |>
    List.filter
    ( fun dir ->
      if !flag_ref then
        true
      else
      ( if (dir = "_build") || (dir = "build") then
          flag_ref := true;
        false
      )
    ) |>
  List.rev |>
  function
  | []  -> failwith "Dryunit is not being preprocessed from build directory"
  | l -> sep ^ (String.concat sep l) ^ sep ^ ".dryunit"


let cache_file ~main =
  let dir = cache_dir () in
  if not @@ Sys.file_exists dir then
    Unix.mkdir dir 0o755;
  let hash = Digest.(to_hex @@ bytes main) in
  dir ^ sep ^ hash


let save_cache ~main suites =
  let path = cache_file ~main in
  if Sys.file_exists path then
    Sys.remove path;
  let c = open_out_bin path in
  Marshal.to_channel c suites [];
  flush c;
  close_out c;
  ()


let load_cache ~main =
  let path = cache_file ~main in
  print_endline ("checking cache from " ^ path);
  if Sys.file_exists path then
  ( let c = open_in_bin path in
    let suites : testsuite list = Marshal.from_channel c in
    close_in c;
    Some suites
  )
  else
  ( print_endline ("File does not exists: " ^ path);
    None
  )


let detect_suites ~filename : testsuite list =
  ( match load_cache ~main:filename with
    | Some suites -> print_endline ">> Found some cache!"
    | None -> print_endline ">> No cache yet, sorry."
  );
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
  |> fun suites ->
  let () = save_cache ~main:filename suites in
  suites


let pp name tests =
  print_endline ("Tests in `" ^ name ^ "`");
  List.iter (fun t -> Printf.printf " - %s [%s]\n" t.test_title t.test_name) tests

let debug ~filename : string =
  let tests = ref [] in
  let _ : unit =
    detect_suites ~filename
    |> List.iter
       ( fun suite ->
         tests := !tests @ suite.tests
      )
  in
  String.concat "\n" (List.map (fun test -> test.test_title) !tests)


module Test = struct
  let name (t:test) = t.test_name
  let title (t:test) = t.test_title
end

let extract_name_from_file ~filename =
  capitalize_ascii

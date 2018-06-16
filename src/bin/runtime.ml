open Printf
open Util

open Model
open TestDescription
open TestSuite


let title_from (v:string) : string =
  Bytes.to_string @@ capitalize_ascii (Util.util_title_from (Bytes.of_string v))


let title_from_no_padding (v:bytes) : string  =
  Bytes.to_string @@ capitalize_ascii (Util.util_title_from_filename v)


let in_build_dir () =
  is_substring (Sys.getcwd ()) "build/"


let should_ignore ~ignore name =
  match ignore with
  | [] -> false
  | _ -> List.exists (fun v -> Util.is_substring name v) ignore


(* XXX: we could add support for inline namespaced tests here *)
let rec should_ignore_path ~only path =
  ( match only with
    | [] -> false
    | _ -> List.exists (fun v -> Util.is_substring path v) only
  )


let extract_from ~filename : TestDescription.t list =
  tests_from filename |>
  List.map
    (fun line ->
      let test_name = fun_name line in
      let test_title : string = title_from test_name in
      let test_loc =
        ( let bytes = Bytes.of_string line in
          let idx = (Bytes.index bytes '[') in
          Bytes.sub bytes idx (Bytes.length bytes - idx - 1) |> Bytes.to_string
        ) in
      let test_mods = Mod_parser.of_function_name test_name in
      { test_name; test_title; test_loc; test_mods }
    )



let suite_from ~dir filename : TestSuite.t =
  (* XXX: experimental code *)
  let suite_path =
    let dir = path_relative_to_workspace @@
      if dir = "." then Sys.getcwd () else dir in
    dir ^ sep ^ filename in
  let suite_full_path =
    let dir = if dir = "." then Sys.getcwd () else dir in
    dir ^ sep ^ filename in
  let name = (Filename.basename filename) in
  let suite_title =
    let s = String.trim @@ title_from_no_padding (to_bytes (Filename.chop_suffix name "tests.ml")) in
    let len = String.length s in
    if len > 0 then s
    else "Tests" in
  { suite_name = to_string @@ capitalize_ascii (to_bytes (Filename.chop_suffix name ".ml"));
    suite_title;
    suite_full_path;
    timestamp = timestamp_from suite_full_path;
    tests = extract_from ~filename:(sprintf "%s%s%s" dir sep name);
    suite_path
  }


let test_name ~current_module suite test =
  if current_module then
    test.test_name
  else
    (suite.suite_name ^ "." ^ test.test_name)


let is_test_file ~main_basename ~ignore_path path =
  if path = main_basename then
    false
  else
    ( let basename = Bytes.of_string @@ Filename.basename path in
      let len = Bytes.length basename in
      try
        ( if Bytes.index basename '.' == (len - 3) && len > 7 then
            let c = Bytes.get basename (len - 8) in
            if c == 't' || c == 'T' then
              if ends_with path "ests.ml" then
                not (should_ignore_path ~only:ignore_path (to_string basename))
              else false
            else false
          else false
        )
      with Not_found -> false
    )


let detect_suites ~filename ~custom_dir ~cache_active ~(ignore_path:string list) : TestSuite.t list =
  let cache = Cache.load_suites ~main:filename ~custom_dir ~cache_active in
  let cache_dirty = ref false in
  let dir = Filename.dirname filename in
  let main_basename = Filename.basename filename in
  Sys.readdir dir |>
  Array.to_list |>
  List.filter ( is_test_file ~main_basename ~ignore_path  ) |>
  (* only over records already in cache, invalidating the cache if needed *)
  List.map
  ( fun filename ->
    ( match Cache.get ~dir ~cache filename with
      | Some suite -> suite
      | None ->
        ( cache_dirty := true;
          suite_from ~dir filename
        )
    )
  ) |>
  fun suites ->
  if !cache_dirty then
    Cache.save_suites ~main:filename ~custom_dir ~cache_active suites;
  suites


let pp name tests =
  print_endline ("Tests in `" ^ name ^ "`");
  List.iter (fun t -> Printf.printf " - %s [%s]\n" t.test_title t.test_name) tests


let print_tests_from ~filename : string =
  let tests = ref [] in
  let _ : unit =
    detect_suites ~filename ~custom_dir:None ~cache_active:true ~ignore_path:[] |>
    List.iter
    ( fun suite ->
      tests := !tests @ suite.tests
    ) in
  !tests |>
  List.map (fun test -> test.test_title) |>
  List.sort String.compare |>
  String.concat "\n"


module Test = struct
  let name (t:TestDescription.t) = t.test_name
  let title (t:TestDescription.t) = t.test_title
end


let extract_name_from_file ~filename =
  capitalize_ascii


let filter_from ~throw ~name value : string list =
  let l = split " " value in
  List.iter
    ( fun v ->
      if String.length v < 4 then
        throw (sprintf "Each word in the field `%s` must be at least 3 chars long" name);
      if v = "test" then
        throw (sprintf "You are not allowed to use the word `test` in the field `%s`" name)
    )
    l;
  l


let should_ignore ~ignore name =
  match ignore with
  | [] -> assert false
  | _ -> List.exists (fun v -> Util.is_substring name v) ignore


let should_filter ~only name =
  match only with
  | [] -> assert false
  | _ -> List.exists (fun v -> Util.is_substring name v) only


let apply_filters ~only ~(ignore:string list) suites =
  let only_tests tests =
    ( if List.length ignore == 0 then tests
      else
        List.filter (fun test -> not (should_ignore ~ignore test.test_name)) tests
    ) |>
    fun tests ->
    ( if List.length only == 0 then tests
      else
        List.filter (fun test -> should_filter ~only test.test_name) tests
    )
  in
  ( List.fold_left
      ( fun acc suite ->
        match only_tests suite.tests with
        | [] -> acc
        | active_tests -> { suite with tests = active_tests } :: acc
      )
      []
      suites
  )


let validate_filters ~throw ~ignore ~only =
  match ignore, only with
  | [], [] -> ()
  | _v, [] -> ()
  | [], _v -> ()
  | _ ->
    List.iter
      ( fun v_filter ->
        if List.exists (fun v -> v_filter = v) ignore then
          throw (sprintf "Query `%s` appears in the fields `filter` and `ignore`." v_filter)
      )
      only

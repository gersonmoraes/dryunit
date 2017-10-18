open Printf
open Core_capitalize
open Core_util

module TestDescription = struct
  type t = {
    test_name: string;
    test_title: string;
  }
end

module TestSuite = struct
  type t = {
    suite_title: string;
    suite_name: string;
    suite_path: string;
    timestamp: float;
    tests: TestDescription.t list;
  }
end

module TestFramework = struct
  type t = Alcotest | OUnit

  let of_string = function
    | "alcotest" -> Alcotest
    | "ounit" -> OUnit
    | other -> raise (Invalid_argument ("Not supported test framework: " ^ other))

  let to_string = function
    | Alcotest -> "alcotest"
    | OUnit -> "ounit"
end

open TestDescription
open TestSuite


let title_from v = capitalize_ascii @@ title_from v
let title_from_no_padding v = capitalize_ascii @@ title_from_filename v

let in_build_dir () =
  is_substring (Sys.getcwd ()) "build/"

let should_ignore ~ignore name =
  match ignore with
  | [] -> false
  | _ -> List.exists (fun v -> Core_util.is_substring name v) ignore


let protected_namespace path =
  if path = "self.ml" then
    true
  else
    ( let len = String.length path in
      if len > 11 then
        if String.(sub path 0 5) = "self_" then
          String.(sub path (length path - 9) 8) = "_Test.ml"
        else false
      else false
    )


(* XXX: we could add support for inline namespaced tests here *)
let rec should_ignore_path ~filter path =
  if protected_namespace path then
    false
  else
    ( match filter with
      | [] -> false
      | _ -> List.exists (fun v -> Core_util.is_substring path v) filter
    )

let extract_from ~filename : TestDescription.t list =
  tests_from filename |>
  List.map
  (fun test_name ->
    { test_name; test_title = title_from test_name }
  )


let timestamp_from filename =
  Unix.((stat filename).st_mtime)

let suite_from ~dir filename : TestSuite.t =
  let name = (Filename.basename filename) in
  { suite_name = capitalize_ascii (Filename.chop_suffix name ".ml");
    suite_title = title_from_no_padding (Filename.chop_suffix name ".ml");
    suite_path = dir ^ sep ^ filename;
    timestamp = timestamp_from (dir ^ sep ^ filename);
    tests = extract_from ~filename:(format "%s%s%s" dir sep name)
  }

let test_name ~current_module suite test =
  if current_module then
    test.test_name
  else
    (suite.suite_name ^ "." ^ test.test_name)

let cache_dir () =
  let flag_ref = ref false in
  let root_found = ref "" in
  Str.split (Str.regexp sep) (Sys.getcwd ()) |>
  List.rev |>
  List.filter
    ( fun dir ->
      if !flag_ref then
        true
      else
      ( if (dir = "_build") || (dir = "build") then
        ( flag_ref := true;
          root_found := dir;
        );
        false
      )
    ) |>
  List.rev |>
  function
  | []  -> failwith "Dryunit is not being preprocessed from build directory"
  | l -> sep ^ (String.concat sep l) ^ sep ^ !root_found ^ sep ^ ".dryunit"


let cache_file ~main ~custom_dir =
  let dir =
    ( match custom_dir with
      | None -> cache_dir ()
      | Some dir -> dir
    ) in
  (* let dir = cache_dir () in *)
  if not @@ Sys.file_exists dir then
    Unix.mkdir dir 0o755;
  close_out (open_out (dir ^ sep ^ ".jbuilder-keep"));
  let hash = Digest.(to_hex @@ bytes (main ^ Sys.ocaml_version)) in
  dir ^ sep ^ hash

let save_cache ~main ~custom_dir ~cache_active suites =
  if not cache_active then ()
  else
  ( let path = cache_file ~main ~custom_dir in
    if Sys.file_exists path then
      Sys.remove path;
    let c = open_out_bin path in
    Marshal.to_channel c suites [];
    flush c;
    close_out c
  )


let load_cache ~main ~custom_dir ~cache_active =
  let path = cache_file ~main ~custom_dir in
  if cache_active && Sys.file_exists path then
  ( let c = open_in_bin path in
    let suites : TestSuite.t list = Marshal.from_channel c in
    close_in c;
    suites
  )
  else []

let get_from_cache ~cache ~dir filename : TestSuite.t option =
  try
    let filename = dir ^ sep ^ filename in
    List.find
    ( fun s ->
      if s.suite_path = filename  then
        if timestamp_from s.suite_path = s.timestamp then
          true
        else false
      else false
    )
    cache |>
    fun s ->
    Some s
  with
    Not_found -> None

let detect_suites ~filename ~custom_dir ~cache_active ~ignore_path : TestSuite.t list =
  let cache = load_cache ~main:filename ~custom_dir ~cache_active in
  let cache_dirty = ref false in
  let dir = Filename.dirname filename in
  let main_basename = Filename.basename filename in
  Sys.readdir dir |>
  Array.to_list |>
  List.filter
  ( fun v ->
    if v = main_basename then
      false
    else
    ( let basename = Filename.basename v in
      let len = String.length basename in
      if (ends_with v ".ml") && (Bytes.index basename '.' == (len - 3)) then
        not (should_ignore_path ~filter:ignore_path basename)
      else
        false
    )
  ) |>
  (* filter over records already in cache, invalidating the cache if needed *)
  List.map
  ( fun filename ->
    ( match get_from_cache ~dir ~cache filename with
      | Some suite -> suite
      | None ->
        ( cache_dirty := true;
          suite_from ~dir filename
        )
    )
  ) |>
  fun suites ->
  if !cache_dirty then
    save_cache ~main:filename ~custom_dir ~cache_active suites;
  suites

let pp name tests =
  print_endline ("Tests in `" ^ name ^ "`");
  List.iter (fun t -> Printf.printf " - %s [%s]\n" t.test_title t.test_name) tests

let print_tests_from ~filename : string =
  let tests = ref [] in
  let _ : unit =
    detect_suites ~filename ~custom_dir:None ~cache_active:true ~ignore_path:[]
    |> List.iter
       ( fun suite ->
         tests := !tests @ suite.tests
      )
  in
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

let mkdir_p dir =
  split sep dir |>
  List.fold_left
  ( fun acc basename ->
    let path = acc ^ sep ^ basename in
    if not (Sys.file_exists path) then
      Unix.mkdir path 0o755;
    path
  )
  "" |>
  ignore


let filter_from ~throw ~name value : string list =
  let l = split " " value in
  List.iter
    ( fun v ->
      if String.length v < 4 then
        throw (format "Each word in the field `%s` must be at least 3 chars long" name);
      if v = "test" then
        throw (format "You are not allowed to use the word `test` in the field `%s`" name)
    )
    l;
  l


let should_ignore ~ignore name =
  match ignore with
  | [] -> assert false
  | _ -> List.exists (fun v -> Core_util.is_substring name v) ignore

let should_filter ~filter name =
  match filter with
  | [] -> assert false
  | _ -> List.exists (fun v -> Core_util.is_substring name v) filter


let apply_filters ~filter ~ignore suites =
  let filter_tests tests =
    ( if List.length ignore == 0 then tests
      else
        List.filter (fun test -> not (should_ignore ~ignore test.test_name)) tests
    ) |>
    fun tests ->
    ( if List.length filter == 0 then tests
      else
        List.filter (fun test -> should_filter ~filter test.test_name) tests
    )
  in
  ( List.fold_left
      ( fun acc suite ->
        match filter_tests suite.tests with
        | [] -> acc
        | active_tests -> { suite with tests = active_tests } :: acc
      )
      []
      suites
  )

let validate_filters ~throw ~ignore ~filter =
  match ignore, filter with
  | [], [] -> ()
  | _v, [] -> ()
  | [], _v -> ()
  | _ ->
    List.iter
      ( fun v_filter ->
        if List.exists (fun v -> v_filter = v) ignore then
          throw (format "Query `%s` appears in the fields `filter` and `ignore`." v_filter)
      )
      filter

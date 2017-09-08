open Printf

module Util = struct

let is_substring string substring =
  let string, substring = Bytes.of_string string, Bytes.of_string substring in
  let ssl = Bytes.length substring and sl = Bytes.length string in
  if ssl = 0 || ssl > sl then false else
    let max = sl - ssl and clone = Bytes.create ssl in
    let rec check pos =
      pos <= max && (
        Bytes.blit string pos clone 0 ssl ; clone = substring
        || check (Bytes.index_from string (succ pos) (Bytes.get substring 0))
      )
    in
    try check (Bytes.index string (Bytes.get substring 0))
    with Not_found -> false

let starts_with s1 s2 =
  let open  String in
  let len1, len2 = length s1, length s2 in
  if len1 == len2 then
    s1 = s2
  else if len1 < len2 then
    false
  else begin
    (sub s1 0 len2) = s2
  end

let ends_with s1 s2 =
  let open  String in
  let len1, len2 = length s1, length s2 in
  if len1 == len2 then
    s1 = s2
  else if len1 < len2 then
    false
  else begin
    (sub s1 (len1 - len2) len2) = s2
  end

(*
  Hardcore filter to let bindings starting with "test_"
  It does not recognizes test functions inside nested modules
*)
let is_possible_test_entry (line:string) =
  let open String in
  if length line > 20 then
    if get line 7 == ' ' then
      if get line 10 == 'P' then
        if get line 15 == 'v' then
          (sub line 20 4) = "test"
        else false
      else false
    else false
  else false

(**
  Definition used in parsing logic.

  When a new test entry is added, we activate probation logic,
  that checks the following input lines until we know it's not
  a false positive.
 *)
type probation = {
  active: bool ref;
  time: int ref;
}

(* limit for probation iterations, assiciated with time counter *)
let deadline = 14

let fun_name line : string =
  String.(sub line 20 ((index_from line 21 '"') - 20))

let new_probation () = {
  active = ref false;
  time = ref 0;
}

let start_probation ~probation () =
  probation.active := true;
  probation.time := 0

let reset_probation ~probation () =
  probation.active := false;
  probation.time := 0

let can_confirm_test_entry line =
  let open String in
  if length line > 20 then
    if get line 7 == ' ' then
      if get line 10 == 'P' then
        if get line 15 == 'v' then
          (sub line 20 5) = "test_"
        else false
      else false
    else false
  else false

let probation_pass ~probation line =
  probation.time := !(probation.time) + 1;
  if !(probation.time) > deadline || String.length line < 8 then
    let () = reset_probation ~probation () in
    Some false
  else
  ( if !(probation.time) > 3 then
    ( if is_substring line "construct \"()\"" then
      let () = reset_probation ~probation () in
      Some true
      else
      ( if is_substring line "_var \"" then (* ounit ctx's param *)
       let () = reset_probation ~probation () in
       Some true
       else None
      )
    )
    else None
  )


let feed_with ~chan =
  let lines = ref [] in
  try
    let probation = new_probation () in
    reset_probation ~probation ();
    while true; do
      let line = input_line chan in
      if !(probation.active) then
      (match probation_pass ~probation line with
        | Some true -> ()
        | Some false ->
            lines := List.tl !lines
        | _ -> ()
      )
      else
      ( if is_possible_test_entry line then
        ( lines := (fun_name line) :: !lines;
          start_probation ~probation ()
        );
      )
    done; !lines
  with End_of_file ->
    close_in chan;
    List.rev !lines



let tests_from path =
  let cmd = Printf.sprintf "ocamlopt -dparsetree %s 2>&1 >/dev/null" path in
  let chan = Unix.open_process_in cmd in
  (* read_with ~filter:is_possible_test_entry ~f:fun_name ~chan:(Unix.open_process_in cmd) *)
  feed_with ~chan



(* let name_from_line line =
  let is_test line =
    starts_with line "val test" && ends_with line " : unit -> unit" in
  if is_test line then
    ( let name = String.sub line 4 ((String.length line)-19) in
      name
    )
  else "" *)

(**
   Extracts a human friendly name from the test function.
   Ex: format "test_it_works" outputs "It works"
*)
let title_from name =
  let name = Bytes.of_string name in
  let name =
    if (Bytes.get name 4) = '_' then
      Bytes.sub name 4 ((Bytes.length name) - 4)
    else name in
  let i, len = ref 0, Bytes.length name in
  while !i < len do
    try
      i := Bytes.index_from name !i '_';
      Bytes.set name !i ' ';
      i := !i + 1;
    with
      _ -> i := len;
  done;
  name |> Bytes.trim |> Bytes.to_string


let title_from_filename name =
  let name = Bytes.of_string name in
  let len = Bytes.length name in
  let i, len = ref 0, len in
  while !i < len do
    try
      i := Bytes.index_from name !i '_';
      Bytes.set name !i ' ';
      i := !i + 1;
    with
      _ -> i := len;
  done;
  name |> Bytes.trim |> Bytes.to_string
end

open Util



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

let timestamp_from filename =
  Unix.((stat filename).st_mtime)

let suite_from ~dir filename : testsuite =
  let name = (Filename.basename filename) in
  { suite_name = capitalize_ascii (Filename.chop_suffix name ".ml");
    suite_title = title_from_no_padding (Filename.chop_suffix name ".ml");
    suite_path = dir ^ sep ^ filename;
    timestamp = timestamp_from (dir ^ sep ^ filename);
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
  if Sys.file_exists path then
  ( let c = open_in_bin path in
    let suites : testsuite list = Marshal.from_channel c in
    close_in c;
    suites
  )
  else []

let get_from_cache ~cache ~dir filename : testsuite option =
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

let detect_suites ~filename : testsuite list =
  let cache = load_cache ~main:filename in
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
      (ends_with v ".ml") && (Bytes.index basename '.' == (len - 3))
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
    save_cache ~main:filename suites;
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
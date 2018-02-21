open Util

open Model
open TestDescription
open TestSuite

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
  | []  -> ".dryunit"
  | l -> sep ^ (String.concat sep l) ^ sep ^ !root_found ^ sep ^ ".dryunit"


let cache_file ~main ~custom_dir =
  let dir =
    ( match custom_dir with
      | None -> cache_dir ()
      | Some dir -> dir
    ) in
  Util.create_dir dir;
  close_out (open_out (dir ^ sep ^ ".jbuilder-keep"));
  let s : bytes = Bytes.of_string (main ^ Sys.ocaml_version) in
  let hash = Digest.(to_hex @@ bytes s) in
  dir ^ sep ^ hash

let save_suites ~main ~custom_dir ~cache_active suites =
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


let load_suites ~main ~custom_dir ~cache_active =
  let path = cache_file ~main ~custom_dir in
  if cache_active && Sys.file_exists path then
  ( let c = open_in_bin path in
    let suites : TestSuite.t list = Marshal.from_channel c in
    close_in c;
    suites
  )
  else []

let get ~cache ~dir filename : TestSuite.t option =
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

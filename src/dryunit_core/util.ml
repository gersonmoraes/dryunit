
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



(* let read_with ~chan ~filter ~f =
  let lines = ref [] in
  try
    while true; do
      let l = input_line chan in
      if filter l then
        lines := f l :: !lines;
    done; !lines
  with End_of_file ->
    close_in chan;
    List.rev !lines *)

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
  ( if !(probation.time) > 5 then
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
      ( match probation_pass ~probation line with
        | Some true -> ()
        | Some false -> lines := List.tl !lines
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
  |> String.capitalize_ascii


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
  |> String.capitalize_ascii

(* This scripts validates the output of alcotest *)

(*
let get_lines filename
  let lines = ref [] in
  let chan = open_in filename in
  try
    while true; do
      lines := input_line chan :: !lines
    done; []
  with End_of_file ->
    close_in chan;
    List.rev !lines


let out =
  let lines = get_lines "main.output"
  let line = input_line c in
  close_in c;
  line

open String

let format s =
  let s : string = trim s in
  let s : string = sub s 0 25 in
  s ^ "}"

let () = print_endline (format out) *)

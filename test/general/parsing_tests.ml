module Sample = struct

  let loc = "[2,1+4]..[2,1+20]"

  let line = 2
  let start = 5
  let length = 21

end

(* first colon *)
let i = String.index Sample.loc ','
let line = String.sub Sample.loc 1 (i - 1)

let test_first_colon () =
  Alcotest.(check int) "first colon" 2 i

let test_first_line () =
  Alcotest.(check string) "line" "2" line

let test_col_start () =
  Alcotest.(check string) "line" "2" line


let next_int ~pos ~buf s : int =
  let is_digit c =
    ( match c with
      | '0' .. '9' -> true
      | _ -> false
    ) in
  while not (is_digit s.[!pos]) do
    incr pos;
  done;
  Buffer.clear buf;
  while is_digit s.[!pos] do
    Buffer.add_char buf s.[!pos];
    incr pos;
  done;
  int_of_string (Buffer.contents buf)


let parse_loc loc =
  let buf, pos = Buffer.create 3, ref 1 in
  let next () = next_int ~pos ~buf loc in
  let line = next () in
  let start = next () + next () in
  let length =
    let _ = next () in
    next () + next () - start in
  line, start, length


let test_reading_ints () =
  let buf = Buffer.create 3 in
  let pos = ref 1 in
  Alcotest.(check int) "n1" 2 (next_int ~pos ~buf Sample.loc);
  Alcotest.(check int) "n2" 1 (next_int ~pos ~buf Sample.loc);
  Alcotest.(check int) "n3" 4 (next_int ~pos ~buf Sample.loc);
  Alcotest.(check int) "n4" 2 (next_int ~pos ~buf Sample.loc);
  Alcotest.(check int) "n5" 1 (next_int ~pos ~buf Sample.loc);
  Alcotest.(check int) "n6" 20 (next_int ~pos ~buf Sample.loc)


let test_parsing_loc () =
  let line, start, length = parse_loc Sample.loc in
  Alcotest.(check int) "line" 2 line;
  Alcotest.(check int) "start" 5 start;
  Alcotest.(check int) "length" 16 length







(*  *)

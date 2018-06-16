
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
  let start =
    let _ = next () in
    next () in
  let length =
    let _ = next (), next () in
    next () - start in
  line, start+1, length

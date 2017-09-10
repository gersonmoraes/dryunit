
let not_implemented () =
  failwith "not implemented yet"


let generate_testsuite_exe framework =
  let get_int () =
    (Random.int 9999) + 1 in
  let id = Printf.sprintf "%d%d%d" (get_int ()) (get_int ()) (get_int ()) in
  let message = "This file is supposed to be generated before build automatically with a " ^
    "random `ID`.\n  Do not include it in your source control." in
  Printf.sprintf "(*\n  %s\n\n  ID = %s\n*)\n\nlet () = [%s%s]\n"
    message id "%" framework

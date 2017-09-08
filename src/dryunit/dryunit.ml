open Printf


let param n =
  try
    Array.get Sys.argv n
  with
  | _ -> "unknown"

let get_int () =
  (Random.int 9999) + 1

let generate_testsuite_exe framework =
  let id = sprintf "%d%d%d" (get_int ()) (get_int ()) (get_int ()) in
  let message = "This file is supposed to be generated before build automatically with a " ^
    "random `ID`.\n  Do not include it in your source control." in
  printf "(*\n  %s\n\n  ID = %s\n*)\n\nlet () = [%s%s]\n"
    message id "%" framework

let () =
  Random.self_init ();
  if ( (Array.length Sys.argv != 3)
       || (not(param 1 = "--gen"))) then
  ( ( Printf.eprintf
      "USAGE:\n  %s --gen (alcotest|ounit)\n\n"
      (Array.get Sys.argv 0)
    );
    exit 1;
  );
  let framework = param 2 in
  if not (framework = "alcotest") && not (framework = "ounit") then
  ( eprintf "Unknown test framework: %s" framework;
    exit 1;
  );
  generate_testsuite_exe framework

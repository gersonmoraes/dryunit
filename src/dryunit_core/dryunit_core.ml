open Util
open Printf

type test = {
  f: string;
  title: string;
}

let extract_from ~filename : test list =
  tests_from filename
  |> List.map
    (fun f ->
       { f; title = title_from_function f }
    )

let pp name tests =
  print_endline ("Tests in `" ^ name ^ "`");
  List.iter (fun t -> Printf.printf " - %s [%s]\n" t.title t.f) tests

let debug ~filename : string =
  extract_from ~filename
  |> List.map (fun v -> v.title)
  |> String.concat "\n"

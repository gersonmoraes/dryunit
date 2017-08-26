open Util

type test = {
  f: string;
  title: string;
}

let extract_from ~name ~filename : test list =
  tests_from filename
  |> List.map
    (fun f ->
       { f; title = title_from_function f }
    )

let pp name tests =
  print_endline ("Tests in `" ^ name ^ "`");
  List.iter (fun t -> Printf.printf " - %s [%s]\n" t.title t.f) tests

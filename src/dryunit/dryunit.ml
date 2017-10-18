let version = "0.4"

let _ =
  let open Core_util in
  let open Types in
  let open Spec in
  let open App in
  let open Action in
  ()

let () =
  Random.self_init ();
  Cmdliner.Term.(exit @@ eval_choice (Spec.default_cmd ~version) Spec.cmds)

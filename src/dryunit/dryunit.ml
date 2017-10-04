let _ =
  let open Util in
  let open Types in
  let open Spec in
  let open App in
  let open Action in
  ()

let () =
  Random.self_init ();
  let version = Version.version in
  Cmdliner.Term.(exit @@ eval_choice (Spec.default_cmd ~version) Spec.cmds)

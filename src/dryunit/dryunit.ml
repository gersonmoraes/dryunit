

let () =
  Random.self_init ();
  let version = "%%VERSION%%" in
  Cmdliner.Term.(exit @@ eval_choice (Spec.default_cmd ~version) Spec.cmds)

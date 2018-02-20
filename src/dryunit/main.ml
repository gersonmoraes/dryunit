open Cmdliner

let version = "0.6.0"
let sdocs = Manpage.s_common_options
let exits = Term.default_exits


let help_secs = [
 `S Manpage.s_common_options;
 `P "These options are common to all commands.";
 `S "MORE HELP";
 `P "Use `$(mname) $(i,COMMAND) --help' for help on a single command.";`Noblank;
 `S Manpage.s_bugs; `P "Check bug reports at http://bugs.example.org.";
]


let gen_opts sort nocache framework cache_dir ignore only ignore_path targets =
  Action.({ sort; nocache; framework; cache_dir; ignore; only; ignore_path; targets; })


let gen_opts_t =
  let docs = "Generate source code for test executable with appropriate code to bootstrap a test framework" in
  let open Arg in
  let sort = value & flag & info ["sort"] ~docs ~doc:"Sort testsuites and test functions. Default is false." in
  let nocache = value & flag & info ["nocache"] ~docs ~doc:"Disable cache." in
  let framework = value & opt (some string) None & info ["framework"] ~docs ~doc:"Define a test framework. Currently only 'alcotest' and 'ounit' are available. The default is 'alcotest'." in
  let cache_dir = value & opt (some string) None & info ["cache-dir"] ~docs ~doc:"Select a custom cache dir." in
  let only = value & opt (some string) None & info ["only"] ~docs ~doc:"Space separated list of words used to filter tests." in
  let ignore = value & opt (some string) None & info ["ignore"] ~docs ~doc:"Space separated list of words used to ignore tests." in
  let ignore_path = value & opt (some string) None & info ["ignore-path"] ~docs ~doc:"Space separated list of words used to ignore files." in
  let targets = value & pos_all string [] & info [] ~docv:"TARGET" in
  Term.(const gen_opts $ sort $ nocache $ framework $ cache_dir $ ignore $ only $ ignore_path $ targets)


let init_opts framework =
  Action.( {framework } )
let init_opts_t =
  let framework =
    Arg.(value & pos 0 string "alcotest" & info [] ~docv:"FRAMEWORK" ~doc:"Define a test framework. The default is 'alcotest'.") in
  Term.(const init_opts $ framework)


let init_cmd =
let doc = "The entrypoint of dryunit. To create a test suite, you can run: " ^
  "`dryunit init > tests/jbuild` and you are all set. Detection should be " ^
  "working and tests should be executed with `jbuilder runtest`. " ^
  "To run a particular test generated with `dryunit init` passing parameters, " ^
  "it's enough to run `jbuilder exec path/to/tests/main.exe -- --param1 --param2`" in
  Term.(ret (const Action.init_executable $ init_opts_t)),
  Term.info "init" ~doc ~sdocs ~exits


let gen_cmd =
  let doc =
    "Generate bootstrap code for the main executable. " ^
    "The entrypoint for dryunit is the command `dryunit init`, which generates
    the jbuilder configuration responsible for setting up the bootstrap code gen.
    Also, it's not advised to execute `dryunit gen` from a directory in source " ^
    "control, because it generates compilation artifacts." in
  Term.(ret (const Action.gen_executable $ gen_opts_t)),
  Term.info "gen" ~doc ~sdocs ~exits


let help_cmd =
  let topic =
    let doc = "The topic to get help on. `topics' lists the topics." in
    Arg.(value & pos 0 (some string) None & info [] ~docv:"TOPIC" ~doc)
  in
  let doc = "show help" in
  Term.(ret
    (const Action.help $ Arg.man_format $ Term.choice_names $ topic)),
  Term.info "help" ~doc ~exits:Term.default_exits


let default_cmd ~version =
  let doc = "a detection tool for traditional testing in OCaml" in
  Term.(ret (const (fun _ -> `Help (`Pager, None)) $ const ())),
  Term.info "dryunit" ~version ~doc ~sdocs ~exits ~man:help_secs


let cmds =
  [ init_cmd
  ; gen_cmd
  ; help_cmd
  ]

let () =
  Random.self_init ();
  Cmdliner.Term.(exit @@ eval_choice (default_cmd ~version) cmds)

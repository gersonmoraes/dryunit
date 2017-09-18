open Cmdliner

(* Help sections common to all commands *)

let help_secs = [
 `S Manpage.s_common_options;
 `P "These options are common to all commands.";
 `S "MORE HELP";
 `P "Use `$(mname) $(i,COMMAND) --help' for help on a single command.";`Noblank;
 `P "Use `$(mname) help patterns' for help on patch matching."; `Noblank;
 `P "Use `$(mname) help environment' for help on environment variables.";
 `S Manpage.s_bugs; `P "Check bug reports at http://bugs.example.org.";]


(* Options common to all commands *)

(* unstable *)
let common_opts debug verb prehook = Action.({ debug; verb; prehook })
let common_opts_t =
  let docs = Manpage.s_common_options in
  let debug =
    let doc = "Give only debug output." in
    Arg.(value & flag & info ["debug"] ~docs ~doc)
  in
  let verb =
    let doc = "Suppress informational output." in
    let quiet = Action.Quiet, Arg.info ["q"; "quiet"] ~docs ~doc in
    let doc = "Give verbose output." in
    let verbose = Action.Verbose, Arg.info ["v"; "verbose"] ~docs ~doc in
    Arg.(last & vflag_all [Action.Normal] [quiet; verbose])
  in
  let prehook =
    let doc = "Specify command to run before this $(mname) command." in
    Arg.(value & opt (some string) None & info ["prehook"] ~docs ~doc)
  in
  Term.(const common_opts $ debug $ verb $ prehook)

(* unstable *)
let gen_opts nocache framework cache_dir ignore filter targets =
  Action.({ nocache; framework; cache_dir; ignore; filter; targets })
let gen_opts_t =
  let docs = Manpage.s_common_options in
  let nocache =
    let doc = "Do not use cache." in
    Arg.(value & flag & info ["nocache"] ~docs ~doc)
  in
  let framework =
    let doc = "Select a test framework." in
    Arg.(required & opt (some string) None & info ["framework"] ~docs ~doc)
  in
  let cache_dir =
    let doc = "Select a custom cache dir." in
    Arg.(value & opt (some string) None & info ["cache-dir"] ~docs ~doc)
  in
  let ignore =
    let doc = "Space separated list of words used to ignore tests." in
    Arg.(value & opt (some string) None & info ["ignore"] ~docs ~doc)
  in
  let filter =
    let doc = "Space separated list of words used to filter tests." in
    Arg.(value & opt (some string) None & info ["filter"] ~docs ~doc)
  in
  let targets = Arg.(value & pos_all string [] & info [] ~docv:"TARGET") in
  Term.(const gen_opts $ nocache $ framework $ cache_dir $ ignore $ filter $ targets)


(* Commands *)

(* unstable *)
let init_cmd =
  let repodir =
    let doc = "Initialize configuration for tests in the project with source root in $(docv)." in
    Arg.(value & opt file Filename.current_dir_name & info ["repodir"]
           ~docv:"DIR" ~doc)
  in
  let doc = "initialize test configuration" in
  let exits = Term.default_exits in
  let man = [
    `S Manpage.s_description;
    `P "Creates a dryunit.toml configuration file";
    `Blocks help_secs; ]
  in
  Term.(const Action.init $ common_opts_t $ repodir),
  Term.info "init" ~doc ~sdocs:Manpage.s_common_options ~exits ~man


(* unstable *)
let gen_cmd =
  let doc = "generate dryunit initialization code" in
  let exits = Term.default_exits in
  let man = [
    `S Manpage.s_description;
    `P "Creates the code to activate dryunit before building the tests";
    `Blocks help_secs; ]
  in
  Term.(const Action.gen $ gen_opts_t),
  Term.info "gen" ~doc ~sdocs:Manpage.s_common_options ~exits ~man


(* unstable *)
let clean_cmd =
  let repodir =
    let doc = "Initialize configuration for tests in the project with source root in $(docv)." in
    Arg.(value & opt file Filename.current_dir_name & info ["repodir"]
           ~docv:"DIR" ~doc)
  in
  let doc = "initialize test configuration" in
  let exits = Term.default_exits in
  let man = [
    `S Manpage.s_description;
    `P "Creates a dryunit.toml configuration file";
    `Blocks help_secs; ]
  in
  Term.(const Action.clean $ common_opts_t $ repodir),
  Term.info "clean" ~doc ~sdocs:Manpage.s_common_options ~exits ~man


(* stable *)
let help_cmd =
  let topic =
    let doc = "The topic to get help on. `topics' lists the topics." in
    Arg.(value & pos 0 (some string) None & info [] ~docv:"TOPIC" ~doc)
  in
  let doc = "display help about darcs and darcs commands" in
  let man =
    [`S Manpage.s_description;
     `P "Prints help about darcs commands and other subjects...";
     `Blocks help_secs; ]
  in
  Term.(ret
    (const Action.help $ common_opts_t $ Arg.man_format $ Term.choice_names $topic)),
  Term.info "help" ~doc ~exits:Term.default_exits ~man


(* stable *)
let default_cmd ~version =
  let doc = "the nearly invisible test framework for OCaml" in
  let sdocs = Manpage.s_common_options in
  let exits = Term.default_exits in
  let man = help_secs in
  Term.(ret (const (fun _ -> `Help (`Pager, None)) $ common_opts_t)),
  Term.info "dryunit" ~version ~doc ~sdocs ~exits ~man

let cmds = [init_cmd; gen_cmd; clean_cmd; help_cmd]

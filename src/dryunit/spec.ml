open Cmdliner
open Core_normalization

(* Help sections common to all commands *)

let help_secs = [
 `S Manpage.s_common_options;
 `P "These options are common to all commands.";
 `S "MORE HELP";
 `P "Use `$(mname) $(i,COMMAND) --help' for help on a single command.";`Noblank;
 `P "Use `$(mname) help patterns' for help on patch matching."; `Noblank;
 `P "Use `$(mname) help environment' for help on environment variables.";
 `S Manpage.s_bugs; `P "Check bug reports at http://bugs.example.org.";
]

let sdocs = Manpage.s_common_options
let exits = Term.default_exits

(* Options common to all commands *)

(* unstable *)
let gen_opts nocache framework cache_dir ignore only ignore_path targets =
  Action.({ nocache; framework; cache_dir; ignore; only; ignore_path; targets; })

let gen_opts_t =
  let docs = "Generate bootstrap code" in
  let open Arg in
  let nocache = value & flag & info ["nocache"] ~docs ~doc:"Do not use cache." in
  let framework = value & opt (some string) None & info ["framework"] ~docs ~doc:"Select a test framework." in
  let cache_dir = value & opt (some string) None & info ["cache-dir"] ~docs ~doc:"Select a custom cache dir." in
  let only = value & opt (some string) None & info ["only"] ~docs ~doc:"Space separated list of words used to filter tests." in
  let ignore = value & opt (some string) None & info ["ignore"] ~docs ~doc:"Space separated list of words used to ignore tests." in
  let ignore_path = value & opt (some string) None & info ["ignore-path"] ~docs ~doc:"Space separated list of words used to ignore files." in
  let targets = Arg.(value & pos_all string [] & info [] ~docv:"TARGET") in
  Term.(const gen_opts $ nocache $ framework $ cache_dir $ ignore $ only $ ignore_path $ targets)

let init_opts framework =
  Action.( {framework } )
let init_opts_t =
  let framework =
    Arg.(value & pos 0 string "alcotest" & info [] ~docv:"FRAMEWORK" ~doc:"Select a framework") in
  Term.(const init_opts $ framework)


(* Commands *)

(* unstable *)
let init_cmd =
  let doc = "shows a template configuration" in
  let man = [
    `S Manpage.s_description;
    `P "Creates a dryunit.toml configuration file";
    `Blocks help_secs; ]
  in
  Term.(ret (const Action.init_executable $ init_opts_t)),
  Term.info "init" ~doc ~sdocs ~exits ~man

let gen_extension_cmd =
  let doc = "Generate dryunit initialization code" in
  let man = [
    `S Manpage.s_description;
    `P "Creates the code to activate dryunit before building the tests";
    `Blocks help_secs; ]
  in
  Term.(ret (const Action.gen_extension $ gen_opts_t)),
  Term.info "extension" ~doc ~sdocs ~exits ~man

let gen_cmd =
  let doc = "Generate dryunit initialization code" in
  let man = [
    `S Manpage.s_description;
    `P "Creates the code to activate dryunit before building the tests";
    `Blocks help_secs; ]
  in
  Term.(ret (const Action.gen_executable $ gen_opts_t)),
  Term.info "gen" ~doc ~sdocs ~exits ~man


(* unstable *)
let clean_cmd =
  let doc = "clean cache" in
  let man = [
    `S Manpage.s_description;
    `P "Use to clean dryunit cache";
    `Blocks help_secs; ]
  in
  Term.(const App.clean $ const ()),
  Term.info "clean" ~doc ~sdocs ~exits ~man


(* stable *)
let help_cmd =
  let topic =
    let doc = "The topic to get help on. `topics' lists the topics." in
    Arg.(value & pos 0 (some string) None & info [] ~docv:"TOPIC" ~doc)
  in
  let doc = "show help" in
  let man =
    [`S Manpage.s_description;
     `P "Prints help about darcs commands and other subjects...";
     `Blocks help_secs; ]
  in
  Term.(ret
    (const Action.help $ Arg.man_format $ Term.choice_names $ topic)),
  Term.info "help" ~doc ~exits:Term.default_exits ~man


(* stable *)
let default_cmd ~version =
  let doc = "a detection tool for traditional testing in OCaml" in
  let man = help_secs in
  Term.(ret (const (fun _ -> `Help (`Pager, None)) $ const ())),
  Term.info "dryunit" ~version ~doc ~sdocs ~exits ~man

let cmds = [init_cmd; gen_cmd; gen_extension_cmd; clean_cmd; help_cmd]

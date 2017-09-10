
type verb = Normal | Quiet | Verbose
type copts = { debug : bool; verb : verb; prehook : string option }

let str = Printf.sprintf
let opt_str sv = function None -> "None" | Some v -> str "Some(%s)" (sv v)
let opt_str_str = opt_str (fun s -> s)
let verb_str = function
  | Normal -> "normal" | Quiet -> "quiet" | Verbose -> "verbose"

let pr_copts oc copts = Printf.fprintf oc
    "debug = %b\nverbosity = %s\nprehook = %s\n"
    copts.debug (verb_str copts.verb) (opt_str_str copts.prehook)

let initialize copts repodir = Printf.printf
    "%arepodir = %s\n" pr_copts copts repodir

(* not_used, just an example *)
let record copts name email all ask_deps files = Printf.printf
    "%aname = %s\nemail = %s\nall = %b\nask-deps = %b\nfiles = %s\n"
    pr_copts copts (opt_str_str name) (opt_str_str email) all ask_deps
    (String.concat ", " files)

let help copts man_format cmds topic = match topic with
| None -> `Help (`Pager, None) (* help about the program. *)
| Some topic ->
    let topics = "topics" :: "patterns" :: "environment" :: cmds in
    let conv, _ = Cmdliner.Arg.enum (List.rev_map (fun s -> (s, s)) topics) in
    match conv topic with
    | `Error e -> `Error (false, e)
    | `Ok t when t = "topics" -> List.iter print_endline topics; `Ok ()
    | `Ok t when List.mem t cmds -> `Help (man_format, Some t)
    | `Ok t ->
        let page = (topic, 7, "", "", ""), [`S topic; `P "Say something";] in
        `Ok (Cmdliner.Manpage.print man_format Format.std_formatter page)

let () =
  Random.self_init ()

let generate_testsuite_exe framework =
  let get_int () =
    (Random.int 9999) + 1 in
  let id = Printf.sprintf "%d%d%d" (get_int ()) (get_int ()) (get_int ()) in
  let message = "This file is supposed to be generated before build automatically with a " ^
    "random `ID`.\n  Do not include it in your source control." in
  Printf.sprintf "(*\n  %s\n\n  ID = %s\n*)\n\nlet () = [%s%s]\n"
    message id "%" framework

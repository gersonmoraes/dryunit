open Util

type verbosity = Normal | Quiet | Verbose

type common_opts =
  { debug   : bool
  ; verb    : verbosity
  ; prehook : string option
  }

let str = Printf.sprintf
let opt_str sv = function None -> "None" | Some v -> str "Some(%s)" (sv v)
let opt_str_str = opt_str (fun s -> s)
let verb_str = function
  | Normal -> "normal" | Quiet -> "quiet" | Verbose -> "verbose"


let pp_common_opts oc common_opts = Printf.fprintf oc
    "debug = %b\nverbosity = %s\nprehook = %s\n"
    common_opts.debug (verb_str common_opts.verb) (opt_str_str common_opts.prehook)


let init common_opts repodir = Printf.printf
    "%arepodir = %s\n" pp_common_opts common_opts repodir


let help common_opts man_format cmds topic =
  match topic with
  | None -> `Help (`Pager, None) (* help about the program. *)
  | Some topic ->
      let topics = "topics" :: "patterns" :: "environment" :: cmds in
      let conv, _ =
        Cmdliner.Arg.enum (List.rev_map (fun s -> (s, s)) topics) in
      ( match conv topic with
        | `Error e -> `Error (false, e)
        | `Ok t when t = "topics" -> List.iter print_endline topics; `Ok ()
        | `Ok t when List.mem t cmds -> `Help (man_format, Some t)
        | `Ok t ->
            let page = (topic, 7, "", "", ""), [`S topic; `P "Say something";] in
            `Ok (Cmdliner.Manpage.print man_format Format.std_formatter page)
      )


type gen_opts =
  { nocache   : bool
  ; framework : string
  ; cache_dir : string option
  ; ignore    : string option
  ; filter    : string option
  ; targets   : string list
  }


let gen { nocache; framework; cache_dir; ignore; filter; targets} =
  let cache_dir = unwrap_or ".dryunit" cache_dir in
  let ignore = unwrap_or "" ignore in
  let filter = unwrap_or "" filter in
  App.gen ~nocache ~framework ~cache_dir ~ignore ~filter ~targets


let clean _common_opts _repodir =
  not_implemented ()

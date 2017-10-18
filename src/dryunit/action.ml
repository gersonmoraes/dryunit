open Core_util
open Core_runtime

let init () =
    App.init ();
    `Ok ()


let help man_format cmds topic =
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
  { nocache    : bool
  ; framework  : string option
  ; cache_dir  : string option
  ; ignore     : string option
  ; filter     : string option
  ; ignore_path: string option
  ; targets    : string list
  }

let catch f () =
  try
    f ();
    `Ok ()
  with
   Failure e -> `Error (false, e)

(* move this to App.gen_extension *)
let gen_extension { nocache; framework; cache_dir; ignore; filter; ignore_path; targets} =
  let cache_dir = unwrap_or "_build/.dryunit" cache_dir in
  let ignore = unwrap_or "" ignore in
  let filter = unwrap_or "" filter in
  let ignore_path = unwrap_or "" ignore_path in
  let framework = unwrap_or "alcotest" framework in
  catch
    ( fun () ->
      App.gen_extension ~nocache ~framework ~cache_dir ~ignore ~filter ~ignore_path ~targets
    ) ()

let gen_executable default_framework { nocache; framework; cache_dir; ignore; filter; ignore_path; targets} =
  let cache_dir = unwrap_or "_build/.dryunit" cache_dir in
  let ignore = unwrap_or "" ignore in
  let filter = unwrap_or "" filter in
  let ignore_path = unwrap_or "" ignore_path in
  let framework = TestFramework.of_string (unwrap_or default_framework framework) in
  let targets = if List.length targets == 0 then [ "main.ml" ] else targets in
  List.iter
    ( fun target ->
        let suites = App.get_suites ~nocache ~framework ~cache_dir ~ignore ~filter ~targets
          ~ignore_path ~detection:"dir" ~main:target in
        App.gen_executable framework suites target
    )
    targets;
  `Ok ()


(* XXX:
    - We don't know yet if we want to support this feature, specially like this
    - This is just a design idea
 *)
type flag =
  [ `Quick
  | `Long
  ]

(* Monad type placeholder *)
type 'a m = 'a

(* Placeholder for the one parameter all test functions should have *)
type ctx = unit

(* Signature for test functions in this test framework *)
type callback =
  | Fun       : (ctx -> unit)                 -> callback
  | Opt       : (ctx -> 'a option)            -> callback
  | Res       : (ctx -> ('ok, 'err) result)   -> callback
  | Async_fun : (ctx -> unit m)               -> callback
  | Async_opt : (ctx -> 'a option m)          -> callback
  | Async_res : (ctx -> ('ok, 'err) result m) -> callback

(* Internals of a test *)
type test =
  { name     : string
  ; loc      : unit -> string
  ; fqdn     : unit -> string
  ; callback : callback
  ; flags    : flag list
  }

(* Internals of a test suite *)
type suite =
  { suite_name  : string
  ; path        : string
  ; flags       : flag list
  ; tests       : test list
  ; mutable has_errors : bool
  }

(* Creating a new test *)
let test ~loc ?(flags=[]) ~fqdn
    ~(f:callback) name
    : test
  =
  { name
  ; loc
  ; fqdn
  ; callback = f
  ; flags
  }

let suite ?(flags=[]) ~tests ~path suite_name : suite =
  { suite_name
  ; path
  ; flags
  ; tests
  ; has_errors = false
  }


(* XXX:
  This is the Api used to wrap test functions with the matching modifiers.
  By default, all modifiers should be inactive.
*)

let wrap_fun f : callback = Fun f
let wrap_opt f : callback = Opt f
let wrap_res f : callback = Res f

let wrap_async_fun f : callback = Async_fun f
let wrap_async_opt f : callback = Async_opt f
let wrap_async_res f : callback = Async_res f


open Printf



module Theme = struct

  module type S = sig
    module Colors : sig
      val yellow: string -> string
      val red: string -> string
      val green: string -> string
      val cyan: string -> string
      val gray: string -> string
      val header_color: string -> string
    end
    module Symbols : sig
      val check_mark: string
      val error_mark: string
      val arrow: string
    end
  end

  type t = (module S)

  module Default : S = struct
    module Colors= struct
      let yellow s = sprintf "\x1b[33m%s\x1b[0m" s
      let red    s = sprintf "\x1b[31m%s\x1b[0m" s
      let green  s = sprintf "\x1b[32m%s\x1b[0m" s
      let cyan   s = sprintf "\x1b[36m%s\x1b[0m" s
      let gray   s = sprintf "\x1b[37m%s\x1b[0m" s
      let header_color v = cyan v
    end
    module Symbols = struct
      let check_mark = "✔"
      let error_mark = "✘"
      let arrow = "➯"
    end
  end

  module Plain : S = struct
    module Colors= struct
      let yellow s = s
      let red    s = s
      let green  s = s
      let cyan   s = s
      let gray   s = s
      let header_color v = cyan v
    end
    module Symbols = struct
      let check_mark = "-"
      let error_mark = "x"
      let arrow = "->"
    end
  end
end

module Terminal = struct


  let run_cmd cmd : string =
    let ic = Unix.open_process_in cmd in
    let all_input = ref [] in
    ( try
        while true do
          all_input := input_line ic :: !all_input
        done
      with
        End_of_file ->
        close_in ic;
    );
    String.concat "\n" !all_input

  let cols () =
    match Terminal_size.get_columns () with
    | Some n -> n
    | None -> 80

  let bold s =
    sprintf "\x1B[1m%s\x1B[0m" s

  let header ?(sep='-') ~header_color name =
    let cols = cols () in
    let separator n =
      String.make n sep in
    eprintf "%s" @@ header_color @@ sprintf "%s( %s %s\n"
      (separator 3)
      (bold name)
      (header_color @@ ")" ^ (separator (cols - (String.length name) - 7)))

end

let () = Random.self_init ()


type my_error =
  | Assertion of Assert.Assert_errors.error
  | Exn of { error: exn; backtrace: string }

let run_test (f: unit -> unit) =
  ( try
      Ok (f ())
    with
      | Assert.Assert_errors.Failure e -> Error (Assertion e)
      | error -> Error (Exn { error; backtrace = Printexc.get_backtrace () })
  )

let process test =
    run_test
      ( fun () -> match test.callback with
        | Fun f -> f ()
        | Res f ->
            ( match f () with
              | Ok _ -> ()
              | Error _ -> failwith "The result contains an Error"
            )
        | _ -> failwith "this callback type is not available yet"
      )

  (* Random.bool () *)
  (* true *)
  (* false *)



let print_loc suite test =
  let line, start, len =
    5, 5, 27
  in
  eprintf  {|File "%s", line %d, characters %d-%d:
|}
  suite.path
  line start len
  let print_error ((module Theme):Theme.t) suite test e =

  let open Theme.Colors in
  let long_assertion () =
    let exp = "A message that should not be put in a long sentence" in
    eprintf {|
    I was expecting:
      "%s"
    but got:
      "%s".

|} exp
   "World"
   in
   let short_assertion () =
      eprintf {|
    I was expecting "%s", but got "%s".

|} "Short" "Things"
  in
  if Random.bool () then
  (* if true then *)
    short_assertion ()
  else
    long_assertion ()
  (* let fqdn = test.fqdn () in *)
  (* eprintf "%s\n%s\n" fqdn @@ red (String.(make (length @@ suite.path) '-')) *)

let run ?(colors=true) name suites =
  let no_colors_env =
    ( try (let _ = Unix.getenv "NOCOLORS" in true)
      with Not_found -> false
    ) in
  let theme : Theme.t =
    if colors && not no_colors_env then
      (module Theme.Default)
    else
      (module Theme.Plain) in
  let module CurrentTheme = (val theme) in
  let open CurrentTheme.Colors in
  let open CurrentTheme.Symbols in

  let total_tests, total_failed = ref 0, ref 0 in
  eprintf "\n";
  List.iter
    ( fun suite ->
      total_tests := !total_tests + (List.length suite.tests);
      Terminal.header ~header_color @@ sprintf "%s with %d tests" suite.suite_name (List.length suite.tests);
      eprintf "\n";
      let failed = ref [] in
      List.iter
        ( fun (test: test) ->
          ( match process test with
            | Ok () ->
              eprintf "  %s " @@ green check_mark;
            | Error e ->
                ( incr total_failed;
                  failed := (test, e) :: !failed;
                  if not suite.has_errors then
                    suite.has_errors <- true;
                  eprintf "  %s " @@ red error_mark;
                )
          );

          eprintf "%s\n" test.name
        )
        suite.tests;
        eprintf "\n";
        if suite.has_errors then
          ( List.iter
              ( fun (test, e) ->
                eprintf "%s %s %s\n"
                  (red "Assertion failed on [") test.name (red "]");
                print_loc suite test;
                print_error theme suite test e;
              )
              !failed;
          );
          eprintf "\n";
    )
    suites;
  Terminal.header ~header_color "Test results";
  eprintf "\n";

  if !total_failed = 0 then
    ( if !total_tests = 1 then
        eprintf "  %s  Your only test %s\n\n" (yellow "➯") (yellow "passed")
      else
        eprintf "  %s  All %d tests %s\n\n" (green "➯") !total_tests (green "passed")
    )
  else
    ( if !total_failed = 1 then
        eprintf "  %s One test %s\n\n" (red arrow) (red "failed")
      else
        ( let failed_suites = (List.length @@ List.filter (fun v -> v.has_errors) suites) in
          let plural = if failed_suites > 1 then "s" else "" in
          eprintf "  %s I got %s in %d suite%s\n\n"
            (red "➯")
            (red @@ sprintf "%d failing tests" !total_failed) failed_suites plural;
        );
      eprintf "\n";
      exit 1;
    )

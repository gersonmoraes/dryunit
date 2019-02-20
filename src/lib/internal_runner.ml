(* Monad type placeholder *)
type 'a m = 'a

(* Placeholder for the one parameter all test functions should have *)
type arg = unit

(* Signature for test functions in this test framework *)
type callback =
  | Fun       : (arg -> unit)                 -> callback
  | Opt       : (arg -> 'a option)            -> callback
  | Res       : (arg -> ('ok, 'err) result)   -> callback
  | Async_fun : (arg -> unit m)               -> callback
  | Async_opt : (arg -> 'a option m)          -> callback
  | Async_res : (arg -> ('ok, 'err) result m) -> callback

(* Internals of a test *)
type test =
  { test_name     : string
  ; test_loc      : string
  ; test_fqdn     : string
  ; test_callback : callback
  ; test_long     : bool
  }

type suite_ctx =
  { ctx_name  : string
  ; ctx_title : string
  ; ctx_path  : string
  }

(* Internals of a test suite *)
type suite =
  { suite_name  : string
  ; suite_path  : string
  ; tests : test list
  ; mutable has_errors : bool
  }

(* Creating a new test *)
(* let test ~loc ~fqdn
    ~(f:callback) test_name
    : test
  =
  { test_name
  ; test_loc = loc
  ; test_fqdn = fqdn
  ; test_callback = f
  ; test_long = false
  } *)

(* let suite ~tests ~path suite_name : suite =
  { suite_name
  ; suite_path = path
  ; tests = tests
  ; has_errors = false
  } *)

let suite_ctx ~name ~title ~path =
  { ctx_name  = name
  ; ctx_title = title
  ; ctx_path  = path
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



let suite ~ctx:info ~(tests:test list) : suite =
  { suite_name = info.ctx_title
  ; suite_path = info.ctx_path
  ; tests
  ; has_errors = false
  }

let test
    test_desc
    ~ctx
    ~name:test_name
    ~f
    ~loc
    : test
  =
  let _ : suite_ctx = ctx in
  { test_name     = test_desc
  ; test_long     = true
  ; test_callback = f
  ; test_loc      = loc
  ; test_fqdn     = (Printf.sprintf "%s.%s" ctx.ctx_name test_name)
  }

let run (_suites: suite list) =
  failwith "DRYUNIT FRAMEWORK IS NOT READY TO RUN"

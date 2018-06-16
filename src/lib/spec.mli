(*
  This interfaces should be validated against custom frameworks in compilation
  time in dryunit.
*)


(* XXX:
    - We don't know yet if we want to support this feature, specially like this
    - This is just a design idea
 *)
type flag

(**
  A monad definition in case of monadic tests. Non-monadic frameworks should
  the id monad [type 'a m = 'a]
 *)
type 'a m

(** Callback argument(s) *)
type ctx = unit

(** Callback types inside this framework *)
type callback

(** A type specifying a test *)
type test

(** A type specifying a testsuite *)
type suite

(* XXX:
    We could use a naming convention for test_X functions, instead of a variant here
 *)
val test:
  loc:(unit -> string)
  -> ?flags:flag list
  -> fqdn:(unit -> string)
  -> f:callback
  -> string
  -> test

val suite:
  ?flags:flag list
  -> tests: test list
  -> path: string
  -> string
  -> suite


(* XXX:
  We should not consider the callback type implementation.
  Instead, we work with these interfaces:
*)

val wrap_fun       : (ctx -> unit)                 -> callback
val wrap_opt       : (ctx -> 'v option)            -> callback
val wrap_res       : (ctx -> ('ok, 'err) result)   -> callback
val wrap_async_fun : (ctx -> unit m)               -> callback
val wrap_async_opt : (ctx -> 'v option m)          -> callback
val wrap_async_res : (ctx -> ('ok, 'err) result m) -> callback


val run: ?colors:bool -> string -> suite list -> unit




















(*  *)

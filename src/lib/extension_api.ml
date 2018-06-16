
  (**
    Interface for custom frameworks
  *)
  module type Runner = sig

    (**
      The signature for a callbacks.

      This can be a polymorphic type. Dryunit is not going to access its
      internal state. Instead, it uses a wraping based function.
     *)
    type callback

    (**
      A type representing a unit test.

      It should include a description of the test and a reference to its callback
     *)
    type test

    (**
      Metadata about the test suite that is to be created.

      An instance of this type is created before any test of the suite is generated.
     *)
    type suite_ctx

    (**
      A high level type holding information on a test suite
    *)
    type suite

    val suite_ctx:
      name: string
      -> title: string
      -> path: string
      -> suite_ctx

    val suite:
      ctx: suite_ctx
      -> tests: test list
      -> suite

    val test:
      string
      -> ctx: suite_ctx
      -> name: string
      -> f: callback
      -> loc: string
      -> test

    val run:
      suites: suite list
      -> unit


    (**
      Single argument for test functions to be used in the signature of wrap-like
      functions
    *)
    type arg

    (**
      A monad type to represent async computations.
    *)
    type 'a m

    val wrap_fun:       (arg -> unit)                 -> callback
    val wrap_opt:       (arg -> 'a option)            -> callback
    val wrap_res:       (arg -> ('ok, 'err) result)   -> callback
    val wrap_async_fun: (arg -> unit m)               -> callback
    val wrap_async_opt: (arg -> 'a option m)          -> callback
    val wrap_async_res: (arg -> ('ok, 'err) result m) -> callback
  end


(**
  Include the default wrappers definitions, including:

    - default callback as [unit -> unit]
    - using the id monad instead of an async lib
    - wrappers raise Failure indicating the expected constructor
*)
module Default_wrappers = struct
  type arg = unit
  type 'a m = 'a
  type callback = unit -> unit

  let wrap_fun f = f
  let wrap_opt f () =
    ( if f () = None then
        failwith "I got the constructor 'None'"
    )
  let wrap_res f () =
    ( match f () with
      | Error _ ->
          failwith "I got the constructor 'Error'"
      | _ -> ()
    )

  let wrap_async_fun = wrap_fun
  let wrap_async_opt = wrap_opt
  let wrap_async_res = wrap_res
end

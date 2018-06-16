module Default_runner = struct

  (* type arg = unit
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
  let wrap_async_res = wrap_res *)

  include Extension_api.Default_wrappers

  type test =
    { test_name : string
    ; test_desc : string
    ; callback  : callback
    ; location  : string
    ; fqdn      : string
    }

  type suite_ctx =
    { suite_name  : string
    ; suite_title : string
    ; suite_path  : string
    }

  type suite =
    { info  : suite_ctx
    ; tests : test list
    }

  let suite_ctx
      ~name:suite_name
      ~title:suite_title
      ~path:suite_path
      : suite_ctx
    =
    { suite_name
    ; suite_title
    ; suite_path
    }

  let suite ~ctx:info ~(tests:test list) : suite =
    { info; tests }

  let test
      test_desc
      ~ctx
      ~name:test_name
      ~f:callback
      ~loc:location
      : test
    =
    { test_name
    ; test_desc
    ; callback
    ; location
    ; fqdn = Printf.sprintf "%s.%s" ctx.suite_name test_name
    }

  let run ~(suites: suite list) =
    failwith "DRYUNIT FRAMEWORK IS NOT READY FOR RUNNING"
end
let _ : (module Extension_api.Runner) = (module Default_runner)


include Default_runner

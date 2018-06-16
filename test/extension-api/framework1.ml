
module TestRunner = struct

  include Dryunit.Extension_api.Default_wrappers

  type test =
    { test_name : string
    ; test_desc : string
    ; callback  : callback
    ; location  : string
    ; fqdn      : string
    }

  type suite_ctx =
    { suite_name: string
    ; suite_title: string
    ; suite_path: string
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

  let run (suites: suite list) =
    ()


end

let _  = (module TestRunner : Dryunit.Extension_api.Runner)


let _ =
  [%dryunit
    { cache_dir = "/path/to/directory"
    ; cache     = true
    ; framework = "alcotest"
    ; ignore    = "query1|query2"
    }
  ]

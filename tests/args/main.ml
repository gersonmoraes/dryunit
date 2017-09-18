
let _ =
  [%dryunit
    { cache_dir = ".dryunit"
    ; cache     = true
    ; framework = "alcotest"
    ; ignore    = "ignored words"
    }
  ]


let _ =
  [%dryunit
    { cache_dir = ".dryunit"
    ; cache     = true
    ; framework = "alcotest"
    ; ignore    = "capita"
    ; filter    = "something capit"
    }
  ]

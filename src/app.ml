open Util
open Printf
open Model
open Runtime


let throw s =
  Printf.eprintf "%s\n" s;
  exit 1


let get_suites ~sort ~nocache ~framework ~cache_dir ~ignore ~only ~targets ~ignore_path ~detection ~main : TestSuite.t list =
  let custom_dir =
    if (cache_dir = ".dryunit") || (cache_dir = "_build/.dryunit") then None
    else
      ( if Util.starts_with cache_dir Filename.dir_sep then
          let () = Util.create_dir cache_dir in
          Some cache_dir
        else
          Some cache_dir
      ) in
  let ignore = filter_from ~throw ~name:"ignore" ignore in
  let only = filter_from ~throw ~name:"only" only in
  let ignore_path = filter_from ~throw ~name:"ignore_path" ignore_path in
  validate_filters ~throw ~ignore ~only;
  let filename = main in
  ( match detection with
    | "dir" -> detect_suites ~filename ~custom_dir ~cache_active:true ~ignore_path
    | "file" -> [ suite_from ~dir:(Filename.dirname filename) (Filename.basename filename) ]
    | _ -> throw "The field `detection` only accepts \"dir\" or \"file\"."
  ) |>
  apply_filters ~only ~ignore |>
  fun suites ->
  ( if sort then
      ( let open TestSuite in
        let open TestDescription in
        let suites = List.map
          ( fun v ->
            { v with tests = List.sort (fun v1 v2 -> String.compare v1.test_title v2.test_title) v.tests }
          )
          suites in
        List.sort (fun v1 v2 -> String.compare v1.suite_title v2.suite_title) suites
      )
    else suites
  )


let gen_executable ~context framework suites oc =
  if List.length suites > 0 then
    ( let f =
      ( match framework with
        | TestFramework.Alcotest -> Serializer.boot_alcotest ~context
        | TestFramework.OUnit ->  Serializer.boot_ounit ~context
      ) in
      f oc suites
    )


let relative_path_of path =
  ( let sep = Filename.dir_sep in
    let flag_ref = ref false in
    Str.split (Str.regexp sep) path |>
    List.filter
      ( fun dir ->
        if !flag_ref then
          true
        else
        ( if (dir = "_build") || (dir = "build") then
            flag_ref := true;
          false
        )
      ) |>
    function
    | []  -> path
    | l -> (String.concat sep @@ List.tl l)
  )









let test_relative_path () =
  ( let full_path = "/home/user1/projects/p1/_build/default/test/subdir1/tests.ml" in
    Alcotest.(check string "relative_path") "test/subdir1/tests.ml" (relative_path_of full_path);
  )

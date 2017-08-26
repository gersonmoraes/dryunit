module To_test = struct
  let capit letter = Char.uppercase_ascii letter
  let plus int_list = List.fold_left (fun a b -> a + b) 0 int_list
end

let test_capit () =
  Alcotest.(check char) "same chars"  'A' (To_test.capit 'a')

let test_plus () =
  Alcotest.(check int) "same ints" 7 (To_test.plus [1;1;2;3])

let _ =
  let _ = [%dryunit_alcotest] in
  ()

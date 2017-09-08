module To_test = struct
  let escape letter = Char.escaped letter
  let plus int_list = List.fold_left (fun a b -> a + b) 0 int_list
end

let test_capit_in_secondary () =
  Alcotest.(check string) "same chars"  "a" (To_test.escape 'a')

let test_capit_in_secondary2 () =
  Alcotest.(check string) "same chars"  "a" (To_test.escape 'a')

(* let test_capit_in_secondary3 () =
  Alcotest.(check string) "same chars"  "a" (To_test.escape 'a') *)

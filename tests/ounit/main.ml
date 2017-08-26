open OUnit2
open Foo

let test_first test_ctxt =
  assert_equal "x" (Char.escaped 'x')

let test_second test_ctxt =
  assert_equal 100 (Foo.unity 100)

let () = [%dryunit_ounit]

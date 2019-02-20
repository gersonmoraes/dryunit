open OUnit2

let test1 _test_ctxt =
  assert_equal "x" (Char.escaped 'x')

let test2 _test_ctxt =
  assert_equal 100 (Foo.unity 100)

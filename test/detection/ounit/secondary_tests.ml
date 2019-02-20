open OUnit

let test_in_secondary _test_ctxt =
  assert_equal 100 (Foo.unity 100)

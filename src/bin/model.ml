module TestDescription = struct
  type t = {
    test_name: string;
    test_title: string;
    test_loc: string;
  }
end


module TestSuite = struct
  type t = {
    suite_title: string;
    suite_name: string;
    suite_full_path: string;
    suite_path: string;
    timestamp: float;
    tests: TestDescription.t list;
  }
end


module TestFramework = struct
  type t = Alcotest | OUnit

  let of_string = function
    | "alcotest" -> Alcotest
    | "ounit" -> OUnit
    | other -> raise (Invalid_argument ("Not supported test framework: " ^ other))

  let to_string = function
    | Alcotest -> "alcotest"
    | OUnit -> "ounit"

  let package = function
    | Alcotest -> "alcotest"
    | OUnit -> "oUnit"
end


module Modifiers = struct
  type t =
    | Async_mod
    | Long_mod
    | Result_mod

  let of_string = function
    | "async"  -> Some Async_mod
    | "lwt"    -> Some Async_mod
    | "long"   -> Some Long_mod
    | "result" -> Some Result_mod
    | other    -> None

  let to_string = function
    | Async_mod  -> "async"
    | Long_mod   -> "long"
    | Result_mod -> "result"
end

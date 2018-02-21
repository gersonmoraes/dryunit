module TestDescription = struct
  type t = {
    test_name: string;
    test_title: string;
  }
end


module TestSuite = struct
  type t = {
    suite_title: string;
    suite_name: string;
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

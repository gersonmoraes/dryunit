
module Assert_errors = struct
  type error =
    | Not_some
    | Not_none
    | Not_ok
    | Not_error
    | Not_empty_list
    | Not_list_length of { exp: int; value: int }
    | Not_array_length of { exp: int; value: int }

  exception Failure of error

  let fail e = raise (Failure e)

  let to_string e =
    ( match e with
      | Not_some         -> "I was expecting the constructor Some"
      | Not_none         -> "I was expecting the constructor None"
      | Not_ok           -> "I was expecting the constructor Ok"
      | Not_error        -> "I was expecting the constructor Error"
      | Not_empty_list   -> "The list is not empty"
      | Not_list_length { exp; value }
      | Not_array_length { exp; value } ->
          Printf.sprintf "I was expected length %d, but got %d" exp value
    )
end

open Assert_errors

let is_some v = function
  | Some _ -> ()
  | None -> fail Not_some

let is_none = function
  | None -> ()
  | Some _ -> fail Not_none

let is_ok = function
  | Ok _ -> ()
  | Error _ -> fail Not_ok

let is_error =  function
  | Ok _ -> fail Not_error
  | Error _ -> ()

let empty_list l = function
  | [] -> ()
  | _ -> fail Not_empty_list

let list_length exp l =
  let value = List.length l in
  if exp <> value then
    fail (Not_list_length { exp; value })

let array_length exp l =
  let value = Array.length l in
  if exp <> value then
    fail (Not_array_length { exp; value })

open Printf

let not_implemented () =
  failwith "not implemented yet"


let generate_testsuite_exe framework =
  let get_int () =
    (Random.int 9999) + 1 in
  let id = sprintf "%d%d%d" (get_int ()) (get_int ()) (get_int ()) in
  let message = "This file is supposed to be generated before build automatically with a " ^
    "random `ID`.\n  Do not include it in your source control." in
  sprintf "(*\n  %s\n\n  ID = %s\n*)\n\nlet () = [%s%s]\n"
    message id "%" framework


module Config = struct

  let force_opt ~k = function
    | None -> invalid_arg @@ sprintf "could not get %s from config" k
    | Some v -> v

  let get_string k toml_table =
    TomlLenses.(get toml_table (key k |-- string)) |> force_opt ~k

  let get_int k toml_table =
    TomlLenses.(get toml_table (key k |-- int)) |> force_opt ~k

  let get_float k toml_table =
    TomlLenses.(get toml_table (key k |-- float)) |> force_opt ~k

  let get_bool k toml_table =
    TomlLenses.(get toml_table (key k |-- bool)) |> force_opt ~k

  let get_bool_array k toml_table =
    TomlLenses.(get toml_table (key k |-- array |-- bools)) |> force_opt ~k

  let get_table k toml_table =
    TomlLenses.(get toml_table (key k |-- table)) |> force_opt ~k

  let get_table_array k toml_table =
    TomlLenses.(get toml_table (key k |-- array |-- tables)) |> force_opt ~k

  let string_of_key = TomlTypes.Table.Key.to_string

  let bool_from = function
    | TomlTypes.TBool v -> v
    | _ -> invalid_arg "value is not a bool"

  (** Used to help filter 'true' values from a boolean(ish) Toml table *)
  let collect ~f k v acc =
    if bool_from v then
      (f @@ string_of_key k)::acc
    else acc

end

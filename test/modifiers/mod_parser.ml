
open Model

module Parser_utils = struct
  let split ~sep v =
    Str.split (Str.regexp sep) v

  let sep = "_"
end
open Parser_utils

module Mods = struct

  type t =
    { async  : bool
    ; echain : bool
    ; result : bool
    ; long   : bool
    }


  let of_list values =
    let async, echain, result, long =
      ref false, ref false , ref false , ref false  in
    let open Modifiers in
    List.iter
      ( function
        | Async   -> async  := true
        | Echain  -> echain := true
        | Long    -> long   := true
        | Result  -> result := true
      )
      values;
    { async  = !async
    ; echain = !echain
    ; result = !result
    ; long   = !long
    }


  let parse_mods parts =
    let rec iter acc parts =
      ( match parts with
        | [] -> acc
        | potential_mod :: tail ->
          ( match Model.Modifiers.of_string potential_mod with
            | Some modifier -> iter (modifier :: acc) tail
            | None -> acc
          )
      ) in
    iter [] parts


  let list_of_path path =
    let parts = List.rev @@ split ~sep path in
    ( if not (List.hd parts = "tests.ml") then
        []
      else
        parse_mods (List.tl parts)
    )


    let of_path path =
      let v = list_of_path path |> of_list in
      ( if v.result && v.echain then
          raise (Invalid_argument "you cannot activate result and echain simultaneously")
      );
      v


end

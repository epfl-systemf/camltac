(** Preprocessing of snippets. *)

(** {1 Preprocessing heuristic}

    Preprocessing can be skipped if the source file does not include
    either the [%] character, or the {v [@ v} character sequence.
 *)

(* OCaml attributes are false positives introduced by the scaffold itself. *)
let ocaml_attribute = "[@@@ocaml"

let is_ocaml_attribute s i =
  match String.sub s i (String.length ocaml_attribute) with
  | s when String.equal s ocaml_attribute -> true
  | _ | exception Invalid_argument _ -> false

let needs_ppx ~source =
  let n = String.length source in
  let rec loop i =
    if i >= n then false
    else
      match source.[i] with
      | '%' -> true
      | '[' when i + 1 < n && source.[i + 1] = '@' ->
         if is_ocaml_attribute source i then loop (i + String.length ocaml_attribute)
         else true
      | _ -> loop (i + 1)
  in
  loop 0

(** {2 Preprocessing} *)

let select_driver ~ppxs ~source =
  match ppxs with
  | [] when needs_ppx ~source -> Ok Ppx_driver.ppx_rocq
  | []                        -> Ok Ppx_driver.empty
  | _                         -> Ppx_driver.build_custom ~ppxs

(** {1 Compiler options} *)

let pp_flag_format : _ format =
  {|%s -as-pp --use-compiler-pp --cookie ppx_rocq.camltac_mode=true|}

let pp_flag driver =
  match Ppx_driver.resolve driver with
  | Some path -> Some (Format.sprintf pp_flag_format path)
  | None      -> None

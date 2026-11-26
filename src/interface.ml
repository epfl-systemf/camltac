(** Reading and parsing OCaml interfaces. *)

(** {1 Interfaces} *)

type t =
  | Value of { typ: string } (** A single value [val __x : typ]. *)
  | Signature of string      (** A whole signature. *)

let parse intf =
  let prefix = "val " ^ Scaffold.single_value_name ^ " :" in
  if String.starts_with ~prefix intf then
    let l = String.length prefix in
    let typ = String.sub intf l (String.length intf - l) in
    Value { typ = String.trim typ }
  else
    Signature intf

let tactic_type =
  let suffix = " tactic" in function
  | Value { typ } when String.ends_with ~suffix typ ->
     let typ = String.sub typ 0 (String.length typ - String.length suffix) in
     Ok (String.trim typ)
  | Value { typ } ->
     Error typ
  | Signature intf ->
     Error (Format.sprintf "sig %s end" intf)

let print = function
  | Value { typ }  -> Pp.(str "- : " ++ str typ)
  | Signature intf -> Pp.str intf

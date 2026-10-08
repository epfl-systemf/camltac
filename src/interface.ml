(** Reading and parsing OCaml interfaces. *)

type t =
  | Single_value of string (** A single value, such as [val __x : typ].
                               The string records the type. *)
  | Signature of string    (** A whole signature. *)

(** An unlikely name, so that it cannot be confused with regular user code. *)
let single_value_name = "__x"

let parse intf =
  let prefix = "val " ^ single_value_name ^ " :" in
  if String.starts_with ~prefix intf then
    let l = String.length prefix in
    let typ = String.sub intf l (String.length intf - l) in
    Single_value (String.trim typ)
  else
    Signature intf

let read mli_file =
  Build_file.locate mli_file
  |> File.read
  |> String.trim
  |> parse

let tactic_type =
  let suffix = " tactic" in function
  | Single_value typ when String.ends_with ~suffix typ ->
     let typ = String.sub typ 0 (String.length typ - String.length suffix) in
     Some (String.trim typ)
  | _ ->
     None

let pp = function
  | Single_value typ -> Pp.(str "- : " ++ str typ)
  | Signature intf -> Pp.str intf

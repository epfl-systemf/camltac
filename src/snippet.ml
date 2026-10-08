(** Representation of OCaml code snippets. *)

(** {1 Snippets} *)

type t =
  { loc: Loc.t;
    contents: string }

let make ~loc contents = { loc; contents }

let read_file ~loc filename =
  try File.read filename
  with File.Not_found ->
    CErrors.user_err ~loc (Pp.(str "File " ++ str filename ++ str " does not exist."))

let of_file ~loc filename =
  let contents = read_file ~loc filename in
  let loc = Loc.{
     fname = InFile { dirpath = None; file = filename };
     line_nb = 1;
     bol_pos = 0;
     bp = 0;
     (* These end locations are obviously wrong, but we don't use this information. *)
     line_nb_last = max_int;
     bol_pos_last = max_int;
     ep = max_int
  } in
  make ~loc contents

let loc { loc; _ } = loc

let contents { contents; _ } = contents

(** {1 Execution modes} *)

type camltac_module =
  { name: (string * Loc.t) option;
    locality: Libobject.locality;
  }

type execution_mode =
  | Eval
  | Check_expression
  | Check_module
  | Module of camltac_module
  | Tactic_in_term
  | Tactic_in_Ltac
  | Tactic_in_Ltac2

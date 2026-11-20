(** OCaml code snippets. *)

(** {1 Snippets} *)

type t =
  { loc: Loc.t;
    contents: string }

(** {2 Constructors} *)

let make ~loc contents = { loc; contents }

let of_file ~file contents =
  let loc = Loc.{
     fname = InFile { dirpath = None; file };
     line_nb = 1;
     bol_pos = 0;
     bp = 0;
     (* These end locations are obviously wrong, but we don't use this information. *)
     line_nb_last = max_int;
     bol_pos_last = max_int;
     ep = String.length contents
  } in
  make ~loc contents

(** {2 Getters} *)

let loc { loc; _ } = loc

let contents { contents; _ } = contents

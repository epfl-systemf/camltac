(** Representation of OCaml code snippets. *)

type t =
  { loc: Loc.t;
    contents: string }

let make ~loc contents = { loc; contents }

let loc { loc } = loc

let contents { contents } = contents


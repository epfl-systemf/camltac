(** Snippet scaffolding. *)

(** {1 Scaffolds} *)

(** A scaffold is a temporary file used for compiling snippets. Its content
    depends on the expected mode of the snippet, i.e., how the snippet should be
    interpreted.

    For example, tactic-in-term snippets should be of type [constr tactic], and
    this constraint is expressed by scaffolding the snippet as
    [let res : constr tactic = <snippet> in res].
 *)

(** The scaffolding mode determines how the scaffold is constructed. *)
type mode =
  | Infer_type                     (** The type of a single value is inferred. *)
  | Tactic                         (** A single tactic value is registered. *)
  | Show_tactic of { typ: string } (** A single tactic value is registered and printed. *)
  | Plain                          (** No scaffolding is performed. *)

val make : mode -> Snippet.t -> string
(** [make mode snippet] scaffolds the given snippet according to [mode]. *)

(** Utilities for manipulating temporary files. *)

(** [with_context ~prefix ~suffix content] creates a temporary file with the given [content].
    The optional [prefix] and [suffix] arguments control filename generation. *)
val with_content : ?prefix:string -> ?suffix:string -> string -> string

(** [with_temp_file ~prefix ~suffix content f] creates a temporary file with the given [content],
    and executes [f] with the path of the temporary file.
    The optional [prefix] and [suffix] arguments control filename generation.

    The temporary file is automatically cleaned-up when [f] finishes executing. *)
val with_temp_file : ?prefix:string -> ?suffix:string -> string -> (string -> 'a) -> 'a


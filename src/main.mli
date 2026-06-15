(** Entry point for Camltac vernacular commands. *)

(** {1 Syntactic interpretation} *)

val compile_file : loc:Loc.t -> string -> Compiler.output
(** [compile_file ~loc file] compiles the given file. *)

val infer_interface : loc:Loc.t -> string -> Compiler.output
(** [infer_interface ~loc file] type-checks the given file. *)

val compile_scaffold : loc:Loc.t -> Snippet.execution_mode -> string -> Compiler.output
(** [compile_scaffold ~loc mode scaffold] compiles the scaffold code [scaffold]
    according to its execution [mode]. *)

val compile_snippet : Snippet.execution_mode -> Snippet.t -> Compiler.output
(** [compile_snippet mode snippet] scaffolds and compiles [snippet] according to
    its execution [mode]. *)

(** {2 Interpretation} *)

val get_type : Compiler.output -> string
(** [get_type output] reads the given [.mli] file and returns the type of the
    tactic. *)

val interpret : Snippet.execution_mode -> Compiler.output -> unit
(** [interpret mode compilation_output] interprets the compilation output
    according to [mode]. *)

(** Handles backtrack state for modules. *)

val is_loaded : string -> bool
(** [is_loaded m] returns [true] if a module named [m] is already loaded into
    the main program. *)

val declare_module : ?local:bool -> string -> Compiler.output -> unit
(** [declare_module ?local m compilation_output] declares a new Camltac module
    named [m]. If [local] is [true], the module is accessible only in the current file. *)

(** Handles backtrack state for modules. *)

(** {1 Loading modules} *)

val is_loaded : string -> bool
(** [is_loaded m] returns [true] if a module named [m] is already loaded into
    the main program. *)

val declare_module : ?local:bool -> string -> Compiler.output -> unit
(** [declare_module ?local m compilation_output] declares a new Camltac module
    named [m]. If [local] is [true], the module is accessible only in the current file. *)

val loaded_dependencies : unit -> string list
(** [loaded_dependencies ()] returns all currently loaded dependencies. *)

(** {1 Module aliases}

    OCaml has namespacing issues: [Loader.load_file] cannot load two modules
    with the same name. To work-around that, we generate fresh names for
    modules, which we link to the name entered by the user through a packing
    module that only contains module aliases. *)

val packing_module : unit -> string option
(** [packing_module ()] returns the name of the module containing module aliases,
    or [None] if there are no loaded modules. *)

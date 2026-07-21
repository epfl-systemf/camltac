(** Handles backtrack state for modules. *)

(** {1 Loading modules} *)

val is_loaded : string -> bool
(** [is_loaded m] returns [true] if a module named [m] is already loaded into
    the main program. *)

val declare_module : locality:Libobject.locality -> string -> Compiler.output -> unit
(** [declare_module ~locality m compilation_output] declares a new Camltac module
    named [m]. The [locality] argument specifies whether the module is accessible outside of the
    current module:

    - If [locality] is [Local], the module is not accessible.
    - If [locality] is [Export], the module is accessible upon [Import]ing the module.
    - If [locality] is [SuperGlobal], the module is accessible upon [Require]ing the module. *)

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

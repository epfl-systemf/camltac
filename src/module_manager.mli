(** Global state manager. *)

(** {1 Compilation state}

    This state comprises all information relevant for compiling a new module
    (i.e. at synterp time). *)

val declare_module : string option -> Compiler.output -> unit
(** [declare_module name compilation_output] declares a new Camltac module
    with the given name. *)

val dependencies : unit -> string list
(** [dependencies ()] returns all dependencies of compiled modules. *)

val modules_dirs : unit -> string list
(** [modules_dirs ()] returns the list of all directories to modules to include. *)

(** {2 Module aliases}

    OCaml has namespacing issues: [Loader.load_file] cannot load two modules
    with the same name. To work-around that, we generate fresh names for
    modules, which we link to the name entered by the user through a packing
    module that only contains module aliases. *)

val packing_module : unit -> string option
(** [packing_module ()] returns the name of the module containing module aliases,
    or [None] if there are no loaded modules. *)

(** {1 Loading modules} *)

val is_loaded : string -> bool
(** [is_loaded m] returns [true] if a module named [m] is already loaded into
    the main program. *)

val load_module : locality:Libobject.locality -> string option -> Compiler.output -> unit
(** [load_module ~locality m compilation_output] loads the Camltac module
    named [m]. The [locality] argument specifies whether the module is accessible outside of the
    current module:

    - If [locality] is [Local], the module is not accessible.
    - If [locality] is [Export], the module is accessible upon [Import]ing the module.
    - If [locality] is [SuperGlobal], the module is accessible upon [Require]ing the module. *)

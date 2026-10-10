(** Global state manager. *)

(** {1 Loading modules} *)

val is_loaded : string -> bool
(** [is_loaded m] returns [true] if a module named [m] is already loaded into
    the main program. *)

val load_module : locality:Libobject.locality -> string option -> Compiler.compiled -> unit
(** [load_module ~locality m compilation_output] loads the Camltac module
    named [m]. The [locality] argument specifies whether the module is accessible outside of the
    current module:

    - If [locality] is [Local], the module is not accessible.
    - If [locality] is [Export], the module is accessible upon [Import]ing the module.
    - If [locality] is [SuperGlobal], the module is accessible upon [Require]ing the module. *)

(** Loaded modules. *)

(** {1 Loaded modules} *)

val is_loaded : string -> bool
(** [is_loaded m] returns [true] if a module named [m] is already loaded. *)

val load_module : locality:Libobject.locality -> name:string option -> Compiler.compiled -> unit
(** [load_module ~locality ~name m] loads the given module in the current state.

    The [locality] argument specifies whether the module is accessible outside
    of the current Rocq module:

    - If [locality] is [Local], the module is not accessible.
    - If [locality] is [Export], the module is available upon [Import].
    - If [locality] is [SuperGlobal], the module is available upon [Require].
 *)

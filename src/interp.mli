(** Interp state. *)

(** {1 Interp state}

    The interp state is the counterpart to the synterp state that keeps
    track of loaded modules. *)

type t
(** Type of interp state. *)

val current : unit -> t
(** [current ()] returns the current interp state. *)

(** {2 Loading modules} *)

val is_loaded : string -> t -> bool
(** [is_loaded m state] returns [true] if [m] is loaded in [state]. *)

val load_module : locality:Libobject.locality -> name:string option -> Compiler.Artifact.t -> unit
(** [load_module ~locality ~name artifact] loads the module artifact
    using {!Module_loader}.

    If [locality] is [Export] or [SuperGlobal], the module is replayed
    at [Import] or [Require] time, respectively. *)

(** Synterp state. *)

(** {1 Synterp state}

    Since compilation runs at synterp time, the synterp state contains state
    relevant to compilation, such as previously defined modules (available by
    name) and available packages.  *)

type t
(** Type of synterp state. *)

val current : unit -> t
(** [current ()] returns the current synterp state. *)

(** {2 Module declaration}

    To correctly compile snippets, we have to declare compiled modules
    to make them available to subsequent compilations. *)

val declare : locality:Libobject.locality -> name:string option -> Compiler.Artifact.t -> unit
(** [declare ~locality ~name artifact] declares a new module in the
    current synterp state.

    If [locality] is [Export] or [SuperGlobal], the declaration is also
    replayed on [Import] and [Require], respectively. *)

(** {2 Getters} *)

val module_exists : string -> t -> bool
(** [module_exists m state] returns [true] if there is a module named [m] in
    [state]. *)

val artifacts : t -> Compiler.Artifact.t list
(** [artifacts state] returns the list of module artifacts in
    [state]. *)

val module_name_map : t -> string CString.Map.t
(** [module_name_map state] returns the mapping from user module names
    to their real unit names in [state].

    A module's unit name may differ from its user name because OCaml
    cannot load two units with the same name, and backtracking can cause
    the same module to be loaded more than once. Snippets can still
    refer to the user name through module aliases of the form [module
    Name = Name_XXX], which are added to the top of each scaffold
    using [module_name_map].
 *)

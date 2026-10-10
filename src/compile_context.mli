(** Contextual arguments to the compiler. *)

(** {1 Compilation state}

    Compiling OCaml code relies on implicit state that includes previously
    defined modules (available by name) and loaded packages. To correctly
    compile snippets, we thus keep track of the following items:

    - The map from module names to compiled shared libraries;
    - The set of packages that are available, as required by a previous snippet;
    - The set of module directories from external packages to include;
    - An alias module to correctly map module names to their mangled (real) name.

    Since compilation runs at synterp time, compilation state is kept in the
    synterp phase as well.
 *)

(** Type of compilation (synterp) state. *)
type state = private
  { modules      : Build_file.t CString.Map.t; (** Map from module names to compiled files. *)
    packages     : CString.Set.t;              (** Loaded library dependencies. *)
    modules_dirs : CString.Set.t;              (** Set of module directories. *)
    alias_module : alias_module;               (** The alias module. *)
  }

(** Type of alias modules. *)
and alias_module

val declare_module : locality:Libobject.locality -> name:(string * Loc.t) option -> Compiler.compiled -> unit
(** [declare_module ~locality ~name out] updates the current compilation state by adding
    the given module. *)

(** {1 Compilation context}

    The compilation context refers broadly to the set of arguments that are
    passed to the compiler, as a function of the current state. The "default"
    context is the set of default arguments that are always passed; usually, the
    context includes more values on top of the default context.
 *)

(** Type of compilation contexts. *)
type t = Compiler.args

val default : t
(** Default compilation context:

    - [packages] includes the list of [rocq-runtime] packages,
      [camltac.plugin.runtime], [camltac.plugin.api], and [ppx_rocq.runtime];
    - [include_dirs] is empty;
    - [open_modules] includes [Api] and [Prelude].
 *)

val current : unit -> t
(** [current ()] returns the current compilation context. *)

(** Pipelines. *)

(** {1 Pipelines} *)

type ('a, 'b) t = 'a -> 'b
(** A pipeline that transforms objects of type ['a] to ['b]. *)

type 'a middleware = ('a, 'a) t
(** A middleware does not transform its input object. *)

(** {1 Pipeline steps} *)

module type PARAMS = sig
  val workspace : Workspace.t
  (** Current workspace. *)

  val file : string
  (** Name of the currently-compiling file. *)

  val args : Compilation_args.t
  (** Compilation arguments. *)

  val aliases : (string * string) list
  (** Module aliases. *)

  val loaded_units : CString.Set.t
  (** Set of loaded units. *)
end

(** Parametrized pipelines. *)
module Make (P : PARAMS) : sig
  val scaffold : Scaffold.kind -> (Snippet.t, string) t
  (** [scaffold kind] scaffolds the snippet according to [kind]. *)

  val create_source_file : (string, Source_file.t) t
  (** [create_source_file] creates a source file for the snippet. *)

  val create_merlin_file : Source_file.t middleware
  (** [create_merlin_file] creates a Merlin file for the source file. *)

  val create_build_file : (Source_file.t, Build_file.t) t
  (** [create_build_file] copies the source file to a build file. *)

  val generate_file : dir:string -> name:string -> (string, Build_file.t) t
  (** [generate_file ~dir ~name] copies the source file to a build file. *)

  val compile : Compiler.mode -> source:Snippet.t -> (Build_file.t, Compiler.Artifact.t) t
  (** [compile mode ~source] compiles the build file. *)

  val declare_module : locality:Libobject.locality -> name:string option -> Compiler.Artifact.t middleware
  (** [declare_module ~locality ~name] declares a compiled module. *)

  val infer_interface : source:Snippet.t -> (Build_file.t, Compiler.Artifact.t) t
  (** [infer_interface ~source] infers the interface of a build file. *)

  val infer_tactic_type : (Snippet.t, string) t
  (** [infer_tactic_type] infers the type of a tactic snippet. *)

end

val parse_interface : (Compiler.Artifact.t, Interface.t) t
(** [parse_interface] parses an interface file. *)

val print_interface : (Interface.t, unit) t
(** [print_interface] prints an interface. *)

val load_module : locality:Libobject.locality -> name:string option -> (Compiler.Artifact.t, unit) t
(** [load_module ~locality ~name] loads a module. *)

val load_tactic : (Compiler.Artifact.t, 'a Proofview.tactic) t
(** [load_tactic] loads an OCaml tactic. *)

val run_tactic : ?proof:Declare.Proof.t -> ('a Proofview.tactic, 'a) t
(** [run_tactic ?proof] runs a tactic in the context of [proof]. *)

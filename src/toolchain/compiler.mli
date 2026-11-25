(** High-level interface to the OCaml compiler. *)

open Camltac_workspace
open Filesystem

(** {1 Compilation artifacts}

    A compilation artifact is a product of compilation. *)

module Artifact : sig
  type t
  (** Type of compilation artifacts. *)

  val unit_name : t -> string
  (** [unit_name artifact] returns the name of the compilation unit. *)

  val dirname : t -> Path.t
  (** [dirname artifact] returns the name of the directory where the
      artifact is stored. *)

  val dependencies : t -> string list
  (** [dependencies artifact] returns the list of package dependencies
      of the artifact. *)

  val file : t -> Build_file.t
  (** [file artifact] returns the underlying file of [artifact]. *)

  (**/**)

  val unsafe_of_file : dependencies:string list -> Build_file.t -> t
  (** [unsafe_of_file ~dependencies file] asserts that [file] is a compiler
      artifact.

      This function is unsafe, in the sense that no checks are performed
      to ensure that the file is indeed a compiler artifact. Hence it
      should not be used unless you are sure that [file] is a
      compilation artifact. *)
end

(** {1 Compilation} *)

(** Type of compilation modes. *)
type mode = Ocamlfind.mode =
  | Shared_library of { linkall : bool }
  (** Build a shared library that can be loaded by [Loader.load_file], i.e.,
      a [.cmxs] file ([-shared]) for native or [.cma] ([-a]) for bytecode. *)

  | Executable of { linkall : bool; linkpkg : bool }
  (** Build an executable [.exe]. *)

  | Compile_only
  (** Only compile, do not link. *)

  | Infer_interface
  (** Infer the interface ([-i]). *)

val compile : args:Compilation_args.t -> mode -> Build_file.t -> (Artifact.t, int) result * Diagnostic.t list
(** [compile ~args mode file] is the main compilation procedure,
    compiling [file] according to compilation [mode]. *)

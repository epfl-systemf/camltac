(** High-level interface to the OCaml compiler. *)

(** {1 Compilation} *)

(** Results from compiling a file. *)
type compiled =
  { file     : Build_file.t; (** Compiled file. *)
    packages : string list;  (** Packages required to load [file]. *)
  }

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

val compile : args:Compilation_args.t -> mode -> Build_file.t -> (compiled, int) result * Diagnostic.t list
(** [compile ~args mode file] is the main compilation procedure,
    compiling [file] according to compilation [mode]. *)

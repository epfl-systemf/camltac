(** Compilation of OCaml snippets. *)

(** {1 Compilation} *)

(** Results from compiling a file. *)
type compiled =
  { file     : Build_file.t; (** Compiled file. *)
    packages : string list;  (** Packages required to load [file]. *)
  }

(** Arguments to pass to {!compile}. *)
type args =
  { packages     : string list; (** Packages to link ([-package]). *)
    include_dirs : string list; (** Directories to include ([-I]). *)
    open_modules : string list; (** Modules to open ([-open]). *)
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

(** {2 Compilation errors} *)

type error
(** Type of compilation errors. *)

val pp_error : error -> Pp.t
(** [pp_error error] pretty-prints the compilation error. *)

(** {2 Compilation method} *)

val compile : args:args -> directives:Build_directives.t -> mode -> Build_file.t -> (compiled, error) result
(** [compile ~args ~directives mode file] is the main compilation procedure,
    compiling [file] according to compilation [mode]. *)

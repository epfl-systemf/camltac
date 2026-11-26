(** Low-level interface to [ocamlfind]. *)

open Camltac_workspace

(** {1 [ocamlfind ocamlc]} *)

(** Compilation mode. *)
type mode =
  | Shared_library of { linkall : bool }
  (** Build a shared library that can be loaded by [Loader.load_file], i.e.,
      a [.cmxs] file ([-shared]) for native or [.cma] ([-a]) for bytecode. *)

  | Executable of { linkall : bool; linkpkg : bool }
  (** Build an executable [.exe]. *)

  | Compile_only
  (** Only compile, do not link. *)

  | Infer_interface
  (** Infer the interface ([-i]). *)

val ocamlc :
  ?native:bool ->
  ?packages:string list ->
  ?include_dirs:string list ->
  ?open_modules:string list ->
  ?optimize:[`O2 | `O3] ->
  ?pp:string ->
  ?extra_args:string list ->
  mode ->
  Build_file.t ->
  (Build_file.t, int) result * Diagnostic.t list
(** [ocamlc mode impl] runs [ocamlfind ocamlc] on the [impl] file
    according to [mode], returning either [Ok output] or [Error code]
    along with a list of diagnostics.

    @param native (default = [Dynlink.is_native])
      Whether to use the native compiler or not.

    @param packages (default = [[]])
      Packages used for compilation.

    @param include_dirs (default = [[]])
      Directories to add to the compilation's search path.

    @param open_modules (default = [[]])
      List of modules automatically [open] while compiling.

    @param optimize (default = [None])
      Sets the optimization level. Only relevant in native mode.

    @param pp (default = [None])
      Command to run as a source-to-source preprocessor.

    @param extra_args (default = [[]])
      Extra set of arguments to pass to the compiler.
 *)

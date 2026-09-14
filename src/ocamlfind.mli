(** Methods wrapping the [ocamlfind] executable. *)

(** {1 Library management} *)

val list_packages : ?prefix:string -> unit -> string list
(** [list_packages ?prefix ()] returns the list of packages
    whose name starts with [prefix]. *)

(** {1 Compilation} *)

val compile :
  ?packages:string list ->
  ?linkall:bool ->
  ?compile_only:bool ->
  ?shared:bool ->
  ?include_dirs:string list ->
  ?open_modules:string list ->
  ?optimize:[`O2 | `O3] ->
  ?extra_args:string list ->
  ?pp:string ->
  ?stop_after:[`parsing | `typing | `lambda] ->
  ?out:string ->
  string ->
  (string, int) result
(** [compile impl] compiles the OCaml [impl] file, returning either [Ok output] or [Error code].

    @param packages (default = [[]])
      List of additional packages for compilation.

    @param linkall (default = [false])
      If true, all modules are linked in the final output, even unreferenced one.

    @param compile_only (default = [false])
      If true, only compile, do not link ([-c]).

    @param shared (default = [false])
      In native mode: builds a shared library ([-shared]).
      In bytecode: builds an archive ([-a]).

      In both cases, the resulting file can be loaded by [Loader.load_file].

    @param include_dirs (default = [[]])
      List of additional directories to add to the compilation's search path.

    @param open_modules (default = [[]])
      List of modules automatically [open] while compiling.

    @param optimize (default = [None])
      Set the optimization level. Only relevant in native mode.

    @param extra_args (default = [[]])
      Extra set of arguments to pass to the compiler.

    @param pp (default = ["ppx_rocq"])
      Executable to run as a preprocessor.

    @param stop_after (default = [None])
      Phase to stop compilation after.

    @param out (default = inferred)
      Output file.

    @param impl
      OCaml implementation file to compile.
 *)

val compile_exe :
  ?packages:string list ->
  ?linkpkg:bool ->
  ?linkall:bool ->
  ?include_dirs:string list ->
  ?open_modules:string list ->
  ?optimize:[`O2 | `O3] ->
  ?extra_args:string list ->
  ?pp:string ->
  string ->
  (string, int) result
(** [compile_exe impl] compiles the OCaml [impl] file to an executable,
    returning either [Ok output] or [Error code].

    @param packages (default = [[]])
      List of additional packages for compilation.

    @param linkpkg (default = [false])
      If true, link the packages in.

    @param linkall (default = [false])
      If true, all modules are linked in the final output, even unreferenced one.

    @param include_dirs (default = [[]])
      List of additional directories to add to the compilation's search path.

    @param open_modules (default = [[]])
      List of modules automatically [open] while compiling.

    @param optimize (default = [None])
      Set the optimization level. Only relevant in native mode.

    @param extra_args (default = [[]])
      Extra set of arguments to pass to the compiler.

    @param pp (default = ["ppx_rocq"])
      Executable to run as a preprocessor.

    @param impl
      OCaml implementation file to compile.
 *)

val infer_interface :
  ?packages:string list ->
  ?include_dirs:string list ->
  ?open_modules:string list ->
  ?extra_args:string list ->
  ?pp:string ->
  string ->
  (string, int) result
(** [infer_interface impl] infers the interface of the OCaml [impl] file,
    returning either [Ok output] or [Error code].

    @param packages (default = [[]])
      List of additional packages for compilation.

    @param include_dirs (default = [[]])
      List of additional directories to add to the compilation's search path.

    @param open_modules (default = [[]])
      List of modules automatically [open] while compiling.

    @param extra_args (default = [[]])
      Extra set of arguments to pass to the compiler.

    @param pp (default = ["ppx_rocq"])
      Executable to run as a preprocessor.

    @param impl
      OCaml implementation file to compile.
 *)

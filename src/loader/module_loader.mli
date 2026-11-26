(** Camltac module loader.

    This module loads compiled OCaml modules into the running Rocq
    process and runs their initializers. *)

open Camltac_toolchain

(** {1 Loading modules}

    Loading a module dynlinks its compiled unit (and its package
    dependencies) and executes its top-level code, which registers
    whatever the module defines, such as tactics and printers. The
    module's name is available to subsequently loaded modules only if it
    is named. *)

val load_module : ?env:Runtime.Environment.t -> name:string option -> Compiler.Artifact.t -> Runtime.Environment.t
(** [load_module ?env ~name artifact] loads [artifact] and returns the
    environment captured while its initializers ran.

    If [name] is [Some _], the module is loaded publicly through
    {!Loader.load_file}; otherwise, the module is private.

    The returned environment records the globalization context of the
    load. Persisting it lets a later replay resolve names the same way
    the original load did.

    If the module was already linked in the current process, [load_module]
    replays the module initializers instead of dynlinking.

    @param env (default = {!Runtime.Environment.empty})
      The environment to load the module in. *)

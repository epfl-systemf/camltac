(** Editor support. *)

open Camltac_toolchain
open Camltac_workspace

(** {1 Merlin files}

    Merlin files are used to control the OCaml language server through
    the [--prefer-dot-merlin] option. *)

val create_merlin_file : workspace:Workspace.t -> args:Compilation_args.t -> Source_file.t -> unit
(** [create_merlin_file ~workspace ~args source] creates a Merlin file
    in the same directory as [source], containing all information
    necessary for IDEs to compile the file correctly. *)

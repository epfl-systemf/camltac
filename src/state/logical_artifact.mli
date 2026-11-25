(** Compiler artifacts with logical paths.

    This file defines the logical counterpart to {!Compiler.Artifact.t}
    which can be safely used in [.vo] files. *)

open Camltac_toolchain

(** {1 Logical artifacts} *)

type t
(** Type of logical compiler artifacts. *)

val of_physical : Compiler.Artifact.t -> t
(** [of_physical artifact] converts a physical artifact to a logical
    artifact. *)

val to_physical : t -> Compiler.Artifact.t
(** [to_physical artifact] resolves the logical artifact to a physical
    artifact. *)

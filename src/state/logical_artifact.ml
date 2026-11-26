(** Compiler artifacts with logical paths. *)

open Camltac_toolchain

(** {1 Logical artifacts} *)

(** A copy of {!Compiler.Artifact.t} suitable for use in [.vo] files. *)
type t =
  { dependencies: string list;
    file: Logical_path.t
  }

let of_physical artifact =
  { dependencies = Compiler.Artifact.dependencies artifact;
    file = Logical_path.of_build_file (Compiler.Artifact.file artifact)
  }

let to_physical { dependencies; file } =
  let file = Logical_path.to_build_file file in
  (* Safety is guaranteed by the invariants of this module. *)
  Compiler.Artifact.unsafe_of_file ~dependencies file

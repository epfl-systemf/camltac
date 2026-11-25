(** Compiler artifacts with logical paths. *)

(** {1 Logical artifacts} *)

(** A copy of {!Compiler.compiled} suitable for use in [.vo] files. *)
type t =
  { dependencies: string list;
    file: Logical_path.t
  }

let of_physical (compiled: Compiler.compiled) =
  { dependencies = compiled.packages;
    file = Logical_path.of_build_file compiled.file
  }

let to_physical { dependencies; file } : Compiler.compiled =
  { packages = dependencies;
    file = Logical_path.to_build_file file
  }

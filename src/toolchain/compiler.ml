(** High-level interface to the OCaml compiler. *)

open Camltac_workspace

(** {1 Compilation artifacts} *)

module Artifact = struct
  type t =
    { dependencies : string list;
      file         : Build_file.t
    }

  let unit_name artifact = Filesystem.Path.module_name (Build_file.resolve artifact.file)
  let dirname artifact = Filename.dirname (Build_file.resolve artifact.file)
  let dependencies artifact = artifact.dependencies
  let file artifact = artifact.file

  let unsafe_of_file ~dependencies file = { dependencies; file }
end

(** {1 Compilation} *)

type mode = Ocamlfind.mode =
  | Shared_library of { linkall : bool }
  | Executable of { linkall : bool; linkpkg : bool }
  | Compile_only
  | Infer_interface

let compile ~(args: Compilation_args.t) mode (impl: Build_file.t) =
  let result, diagnostics =
    Ocamlfind.ocamlc
      ~packages:(args.packages)
      ~include_dirs:(Filename.dirname (Build_file.resolve impl) :: args.include_dirs)
      ~open_modules:(args.open_modules)
      ~optimize:(`O3)
      ~extra_args:("-no-alias-deps" :: "-short-paths" :: args.extras)
      ?pp:args.pp
      mode
      impl
  in
  match result with
  | Ok out     -> Ok Artifact.{ file = out; dependencies = args.packages }, diagnostics
  | Error code -> Error code, diagnostics

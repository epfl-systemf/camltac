(** High-level interface to the OCaml compiler. *)

type compiled =
  { file     : Build_file.t;
    packages : string list
  }

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
  | Ok out     -> Ok { file = out; packages = args.packages }, diagnostics
  | Error code -> Error code, diagnostics

(** Preprocessor drivers. *)

open Filesystem.Path

(** {1 Driver} *)

type t =
  | No_preprocessing
  | Ppx_rocq
  | Custom_driver of Build_file.t

let empty = No_preprocessing
let ppx_rocq = Ppx_rocq

let resolve = function
  | No_preprocessing   -> None
  | Ppx_rocq           -> Some "ppx_rocq" (* TODO: Avoid PATH *)
  | Custom_driver file -> Some (Filename.quote (Build_file.resolve file))

(** {1 Custom drivers} *)

module Custom_driver = struct
  let contents =
    {|let () = Ppxlib.Driver.standalone ()|}

  let build ~workspace ~file ~ppxs =
    (* TODO: Build drivers per project instead of per file. *)
    let hash = Digest.to_hex (Digest.string (String.concat "," ppxs)) in
    let driver = Build_file.generate ~workspace ~dir:(".ppx" / file / hash) ~name:"ppx.ml" contents in
    (* We compile in bytecode mode since it links much faster than native. *)
    Ocamlfind.ocamlc
      ~native:false
      ~packages:(["ppxlib"; "ppx_rocq"] @ ppxs)
      ~extra_args:["-predicates"; "ppx_driver"]
      Ocamlfind.(Executable { linkpkg = true; linkall = true })
      driver
end

(** {2 Caching}

    Since custom drivers only depend on the ppx list, we cache them so
    that they're built only once per process. This is important for
    [Camltac Eval], since it uses a custom driver that includes
    [ppx_rocq] and [ppx_deriving.show].  *)

module Ppx_list = struct
  type t = string list
  let equal = List.equal String.equal
  let hash = Hashtbl.hash
end

module Cache = Hashtbl.Make(Ppx_list)

let cache = Cache.create 4

let memoize ~key f =
  match Cache.find_opt cache key with
  | Some driver -> Ok (Custom_driver driver)
  | None        ->
     match f key with
     | Ok driver -> Cache.add cache key driver; Ok (Custom_driver driver)
     | Error err -> Error err

let build_custom ~workspace ~file ~ppxs =
  let key = List.sort_uniq String.compare ppxs in
  memoize ~key
    (fun ppxs ->
      let result, diagnostics = Custom_driver.build ~workspace ~file ~ppxs in
      ignore diagnostics; (* We can't report them correctly. *)
      result)

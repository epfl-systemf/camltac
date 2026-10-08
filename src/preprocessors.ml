(** Support for building custom preprocessors. *)

type t =
  | Default
  | Custom of Build_file.t

let driver_contents =
  {|let () = Ppxlib.Driver.standalone ()|}

let build_custom ppxs =
  let ppx_driver = Build_file.(write ~kind:Ppx_driver driver_contents) in
  (* We use bytecode mode since it links much faster than native. *)
  Ocamlfind.ocamlc
    ~native:false
    ~packages:(["ppxlib"; "ppx_rocq"] @ ppxs)
    ~extra_args:["-predicates"; "ppx_driver"]
    Ocamlfind.(Executable { linkpkg = true; linkall = true })
    ppx_driver

module Cache = Hashtbl.Make(struct
                   type t = string list
                   let equal = List.equal String.equal
                   let hash = Hashtbl.hash
                 end)

let cache = Cache.create 4

let cached_or_build ppxs =
  match Cache.find cache ppxs with
  | driver -> Ok (Custom driver)
  | exception Not_found ->
     let (let*) = Result.bind in
     let* driver = build_custom ppxs in
     Cache.add cache ppxs driver;
     Ok (Custom driver)

let create ppxs =
  match ppxs with
  | [] -> Ok Default
  | _ ->
     let ppxs = List.sort_uniq String.compare ppxs in
     cached_or_build ppxs

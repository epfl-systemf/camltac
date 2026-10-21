(** Preprocessing of snippets. *)

(** {1 Preprocessing} *)

type t =
  | Skip                   (** No preprocessing is done. *)
  | Ppx_rocq               (** Only [ppx_rocq] applies. *)
  | Custom of Build_file.t (** Custom driver. *)

(** {2 Custom drivers}

    When more than one preprocessor is involved, we combine them in a single
    executable called a {e custom driver}, so that the AST is traversed only once.

    This follows what Dune calls the "fast pipeline" mode:
    {:https://dune.readthedocs.io/en/stable/explanation/preprocessing.html}.
 *)

module Custom_driver = struct
  let contents =
    {|let () = Ppxlib.Driver.standalone ()|}

  let build ~ppxs =
    let driver = Build_file.(write ~kind:Ppx_driver contents) in
    (* We compile in bytecode mode since it links much faster than native. *)
    Ocamlfind.ocamlc
      ~native:false
      ~packages:(["ppxlib"; "ppx_rocq"] @ ppxs)
      ~extra_args:["-predicates"; "ppx_driver"]
      Ocamlfind.(Executable { linkpkg = true; linkall = true })
      driver
end

(** {2 Caching}

    Since custom drivers only depend on the ppx list, we cache them so that
    they're built only once per process. This is important for [Camltac Eval],
    since it uses a custom driver that includes [ppx_rocq] and [ppx_deriving.show].
 *)

module Ppx_list = struct
  type t = string list
  let equal = List.equal String.equal
  let hash = Hashtbl.hash
end

module Cache = Hashtbl.Make(Ppx_list)

let cache = Cache.create 4

let build_custom ~ppxs =
  let ppxs = List.sort_uniq String.compare ppxs in
  match Cache.find_opt cache ppxs with
  | Some driver -> Ok driver
  | None ->
     Custom_driver.build ~ppxs
     |> Result.map (fun (driver, _) -> Cache.add cache ppxs driver; driver)

(** {2 Preprocessing heuristic}

    Preprocessing can be skipped if the source file does not include either
    the [%] character, or the {v [@ v} character sequence.
 *)

(* OCaml attributes are false positives introduced by the scaffold itself. *)
let ocaml_attribute = "[@@@ocaml"

let is_ocaml_attribute s i =
  match String.sub s i (String.length ocaml_attribute) with
  | s when String.equal s ocaml_attribute -> true
  | _ | exception Invalid_argument _ -> false

let contains_ppx_markers ~source =
  let n = String.length source in
  let rec loop i =
    if i >= n then false
    else
      match source.[i] with
      | '%' -> true
      | '[' when i + 1 < n && source.[i + 1] = '@' ->
         if is_ocaml_attribute source i then loop (i + String.length ocaml_attribute)
         else true
      | _ -> loop (i + 1)
  in
  loop 0

(** {2 Preprocessing} *)

let prepare ~ppxs ~source =
  match ppxs with
  | [] ->
     if contains_ppx_markers ~source then Ok Ppx_rocq
     else Ok Skip
  | _ ->
     build_custom ~ppxs
     |> Result.map (fun driver -> Custom driver)

(** {1 Compiler options} *)

let pp_flag_format : _ format =
  {|%s -as-pp --use-compiler-pp --cookie ppx_rocq.camltac_mode=true|}

let pp_flag = function
  | Skip     -> None
  | Ppx_rocq ->
     (* TODO: Point directly to ppx_rocq executable to avoid PATH. *)
     Some (Format.sprintf pp_flag_format "ppx_rocq")
  | Custom driver ->
     let driver = Build_file.locate driver in
     Some (Format.sprintf pp_flag_format (Filename.quote driver))

(** {2 Runtime dependencies}

    Runtime dependencies are libraries that PPX rewriters use to function
    properly. They can be found by looking at the package's META file through
    {!Findlib}.
 *)

(* Make sure that Findlib is initialized. *)
let () = Findlib.init ()

let package_property ?(preds = []) package prop =
  let value = Findlib.package_property preds package prop in
  Fl_split.in_words value

let runtime_deps ppx =
  (* Runtime deps are either specified in [ppx_runtime_deps] (by Dune) or
     in [requires(custom_ppx)]; check the former first. *)
  try package_property ppx "ppx_runtime_deps"
  with Not_found ->
    try package_property ~preds:["custom_ppx"] ppx "requires"
    with Not_found -> []

let runtime_deps ~ppxs =
  List.concat_map runtime_deps ppxs

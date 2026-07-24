(** Handling of top-level attributes for compiler options. *)

open Ppxlib
open Sexplib.Std

(** [[@@@compiler]] floating attribute, used to adds flags to the compiler. *)
module Compiler_options = struct
  (** Property for compiler options, set through the [[@@@compiler]] floating
      attribute. *)
  module Property =
    Driver.Create_file_property
      (struct let name = "compiler_options" end)
      (struct type t = string list [@@deriving sexp] end)

  let pattern =
    let option = Ast_pattern.(estring __) in
    let options = Ast_utils.comma_separated option in
    Ast_pattern.single_expr_payload options

  let attribute =
    Attribute.Floating.(declare "camltac.compiler" Context.structure_item pattern Fun.id)

  let check item =
    match Attribute.Floating.convert_res [attribute] item with
    | Ok (Some options) -> Property.set options
    | _ -> ()
end

(* Make sure that Findlib is initialized to check packages. *)
let () = Findlib.init ()

let check_library lib =
  let packages = Findlib.list_packages' () in
  if List.mem lib packages then Ok ()
  else Error (Spellcheck.spellcheck packages lib)

module Library_attribute = struct
  module Property =
    Driver.Create_file_property
      (struct let name = "libraries" end)
      (struct type t = string list [@@deriving sexp] end)

  (** Check that the library exists using [ocamlfind], otherwise embed an error node. *)
  let check_lib { txt = lib; loc } =
    match check_library lib with
    | Ok () -> lib
    | Error (Some suggestion) ->
       (* TODO: Embed the error instead of raising. It currently does not work
          because PPX complains about a missing [@@@ppxlib.inline.end] *)
       Location.raise_errorf ~loc "Could not find package %s.\n%s" lib suggestion
    | Error None ->
       Location.raise_errorf ~loc "Could not find package %s." lib

  let pattern =
    let library = Ast_pattern.(estring __') in
    let libraries = Ast_utils.comma_separated library in
    Ast_pattern.single_expr_payload libraries

  let attribute =
    Attribute.Floating.(declare "camltac.using" Context.structure_item pattern Fun.id)

  let check item =
    match Attribute.Floating.convert_res [attribute] item with
    | Ok (Some libs) ->
       let libs = List.map check_lib libs in
       Property.set libs
    | _ -> ()
end

(** [[@@@ppx]] floating attribute, used to adds preprocessors. *)
module Ppx_attribute = struct
  module Property =
    Driver.Create_file_property
      (struct let name = "ppx" end)
      (struct type t = string list [@@deriving sexp] end)

  (** Check that the PPX exists using [ocamlfind], otherwise embed an error node. *)
  let check_ppx { txt = ppx; loc } =
    match check_library ppx with
    | Ok () -> ppx
    | Error (Some suggestion) ->
       Location.raise_errorf ~loc "Could not find PPX named %s.\n%s" ppx suggestion
    | Error None ->
       Location.raise_errorf ~loc "Could not find PPX named %s." ppx

  let pattern =
    let ppx = Ast_pattern.(estring __') in
    let ppx_list = Ast_utils.comma_separated ppx in
    Ast_pattern.single_expr_payload ppx_list

  let attribute =
    Attribute.Floating.(declare "camltac.ppx" Context.structure_item pattern Fun.id)

  let check item =
    match Attribute.Floating.convert_res [attribute] item with
    | Ok (Some ppx_list) ->
       let ppx_list = List.map check_ppx ppx_list in
       Property.set ppx_list
    | _ -> ()
end

let ast_iterator =
  object
    inherit Ast_traverse.iter as super

    method! structure_item str =
      Compiler_options.check str;
      Library_attribute.check str;
      Ppx_attribute.check str
  end

(**/**)

let () =
  Ppxlib.Driver.register_transformation
    ~impl:(fun structure -> ast_iterator#structure structure; structure)
    "camltac.directives"

let () = Ppxlib.Driver.standalone ()

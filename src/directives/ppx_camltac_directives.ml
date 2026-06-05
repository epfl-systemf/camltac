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

  let expand ~ctxt options =
    Property.set options;
    []

  let pattern =
    let option = Ast_pattern.(estring __) in
    let options = Ast_utils.comma_separated option in
    Ast_pattern.single_expr_payload options

  let attribute =
    Attribute.Floating.(declare "camltac.compiler" Context.structure_item pattern Fun.id)

  let rule =
    Context_free.Rule.attr_str_floating_expect_and_expand attribute expand
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

  let expand ~ctxt libs =
    let libs = List.map check_lib libs in
    Property.set libs;
    []

  let pattern =
    let library = Ast_pattern.(estring __') in
    let libraries = Ast_utils.comma_separated library in
    Ast_pattern.single_expr_payload libraries

  let attribute =
    Attribute.Floating.(declare "camltac.using" Context.structure_item pattern Fun.id)

  let rule =
    Context_free.Rule.attr_str_floating_expect_and_expand attribute expand
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

  let expand ~ctxt ppx_list =
    let ppx_list = List.map check_ppx ppx_list in
    Property.set ppx_list;
    []

  let pattern =
    let ppx = Ast_pattern.(estring __') in
    let ppx_list = Ast_utils.comma_separated ppx in
    Ast_pattern.single_expr_payload ppx_list

  let attribute =
    Attribute.Floating.(declare "camltac.ppx" Context.structure_item pattern Fun.id)

  let rule =
    Context_free.Rule.attr_str_floating_expect_and_expand attribute expand
end

(**/**)

let () =
  Ppxlib.Driver.register_transformation
    ~rules:[
      Compiler_options.rule;
      Ppx_attribute.rule;
      Library_attribute.rule
    ]
    "camltac.directives"

let () = Ppxlib.Driver.standalone ()

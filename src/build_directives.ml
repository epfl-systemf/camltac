(** Build directives. *)

(** {1 Build directives} *)

type t =
  { libraries        : string list;
    ppx              : string list;
    compiler_options : string list;
  }

let empty =
  { libraries        = [];
    ppx              = [];
    compiler_options = []
  }

let eval_directives =
  { libraries        = [];
    ppx              = ["ppx_deriving.show"];
    compiler_options = []
  }

(** {1 Attributes} *)

open Attributes

(** {2 Flag parsing} *)

let ill_formed ?loc () =
  CErrors.user_err ?loc (Pp.str "Ill-formed attribute value (expected an identifier).")

let subflag_name ~check = function
  | { CAst.v = (value, VernacFlagEmpty); loc } -> check ?loc value
  | { CAst.loc; _ }                            -> ill_formed ?loc ()

let parse_flag_value ~check ?loc = function
  (* key *)
  | VernacFlagEmpty ->
     CErrors.user_err ?loc (Pp.str "Expected a value.")

  (* key="string" *)
  | VernacFlagLeaf (FlagString string) ->
     [check ?loc string]

  (* key=qualid *)
  | VernacFlagLeaf (FlagQualid qualid) ->
     [check ?loc (Libnames.string_of_qualid qualid)]

  (* key(v1, v2, …) *)
  | VernacFlagList flags ->
     List.map (subflag_name ~check) flags

let string_list_parser ~check ?loc acc value =
  Option.default [] acc @ (parse_flag_value ~check value)

(** {2 Validation} *)

let check_package ?loc string =
  let packages = Findlib.list_packages' () in
  if List.mem string packages then string
  else
    (* TODO: Add suggestion using spellcheck (OCaml 5.4). *)
    CErrors.user_err ?loc (Pp.(str "Cannot find package named " ++ str string ++ str "."))

let check_compiler_option ?loc flag =
  (* TODO: Perform verification. *)
  flag

(** {2 Attribute} *)

let attribute : t attribute =
  let open Attributes.Notations in
  let packages name =
    attribute_of_list [name, string_list_parser ~check:check_package]
  in
  let compiler_option_list name =
    attribute_of_list [name, string_list_parser ~check:check_compiler_option]
  in
  (packages "libraries" ++ packages "ppx" ++ compiler_option_list "compiler")
  |> map (fun ((libraries, ppx), compiler_options) ->
         { libraries        = Option.default [] libraries;
           ppx              = Option.default [] ppx;
           compiler_options = Option.default [] compiler_options })

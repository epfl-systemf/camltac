(** Methods for handling the dynamic prelude. *)

let module_registry: (string * string) list ref = ref []

let register module_name filename =
  let real_module_name =
    filename
    |> Filename.basename
    |> Filename.remove_extension
    |> String.capitalize_ascii
  in
  let registry = !module_registry in
  if List.mem_assoc module_name registry then
    let open Pp in
    CErrors.user_err (str "Module " ++ str module_name ++ str " is already defined.")
  else
    module_registry := (module_name, real_module_name) :: !module_registry

let contents () =
  let create_alias (module_name, real_name) =
    Format.sprintf "module %s = %s" module_name real_name
  in
  let aliases = List.map create_alias !module_registry in
  String.concat "\n" aliases

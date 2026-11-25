(** OCaml package management. *)

let () = Findlib.init ()

(** {1 Package management} *)

let packages = lazy (Findlib.list_packages' ())

let package_exists name =
  let packages = Lazy.force packages in
  if List.mem name packages then
    Ok ()
  else
    (* TODO: Add suggestion using spellcheck (OCaml 5.4). *)
    let suggestion = None in
    Error suggestion

(** {1 Package properties} *)

let package_property ?(preds = []) package prop =
  let value = Findlib.package_property preds package prop in
  Fl_split.in_words value

let ppx_runtime_deps ppx =
  (* Runtime deps are either specified in [ppx_runtime_deps] (by Dune) or
     in [requires(custom_ppx)]; check the former first. *)
  try package_property ppx "ppx_runtime_deps"
  with Not_found ->
    try package_property ~preds:["custom_ppx"] ppx "requires"
    with Not_found -> []

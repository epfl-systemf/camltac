(** Dynamic loading of shared libraries using {!Dynlink}. *)

(** {1 Loaded units}

    Dynamically loaded units cannot be unloaded, hence the number of loaded
    units can only grow, and we keep track of them to avoid name clashes.
 *)

let loaded_units = ref Build_file.Set.empty

let is_loaded file =
  Build_file.Set.mem file !loaded_units

(** {1 Loading shared libraries} *)

let load_packages packages =
  Fl_dynload.load_packages packages

let load_file ?(dependencies = []) public unit =
  let file = Build_file.locate unit in
  assert (String.equal (Filename.extension file) (if Dynlink.is_native then ".cmxs" else ".cma"));
  let load =
    match public with
    | `Public -> Dynlink.loadfile
    | `Private -> Dynlink.loadfile_private
  in
  try
    (* Make sure that dependencies are available before loading. *)
    load_packages dependencies;
    Debug.print (fun () -> Pp.(str "Loading file " ++ str file ++ str "."));
    load file;
    loaded_units := Build_file.Set.add unit !loaded_units;
    Debug.print (fun () -> Pp.(str "File " ++ str file ++ str " successfully loaded."));
  with
  | Dynlink.Error (Dynlink.Library's_module_initializers_failed exn) ->
     (* This means that the OCaml code inputted by the user failed.
        In this case, we want to avoid the "execution of module initializers in
        the shared library failed" message, so we re-raise the exception and let
        Rocq print it instead. *)
     raise exn
  | Dynlink.Error e ->
     let message = Dynlink.error_message e in
     CErrors.user_err (Pp.str message)

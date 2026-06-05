(** Dynamic loading of shared libraries using [Dynlink]. *)

let load_packages packages =
  Fl_dynload.load_packages packages

let load_file ~public ?(dependencies = []) file =
  assert (Sys.file_exists file);
  assert (String.equal (Filename.extension file) (if Dynlink.is_native then ".cmxs" else ".cma"));
  let load = if public then Dynlink.loadfile else Dynlink.loadfile_private in
  try
    (* Make sure that dependencies are available before loading. *)
    load_packages dependencies;
    Flags.if_verbose Feedback.msg_debug (Pp.fmt "Loading file %s." file);
    load file;
    Flags.if_verbose Feedback.msg_debug (Pp.fmt "File %s successfully loaded." file);
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

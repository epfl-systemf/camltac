(** Currently-compiling library. *)

open Names

(** {1 Compilation information} *)

let top_module_name () =
  let _, name = Libnames.split_dirpath (Lib.library_dp ()) in
  Id.to_string name

let parent () =
  Libnames.pop_dirpath (Lib.library_dp ())

let cwd () =
  (* Try to locate the parent directory through the loadpath. This gives
     better results that {!Sys.getcwd ()}, which may be set to
     anything. *)
  let parent_path = parent () in
  if DirPath.is_empty parent_path then
    (* This most likely indicates that we are in [rocq top], so it's
       safe to fallback to the current working directory. *)
    Sys.getcwd ()
  else
    match Loadpath.find_with_logical_path parent_path with
    | [] ->
       CErrors.user_err (Pp.(str "Cannot find physical path for "
                             ++ DirPath.print parent_path ++ str "."))
    | loadpath :: _ ->
       (* TODO: Warn on ambiguous loadpath? *)
       Loadpath.physical loadpath

(** Layout of build directories. *)

open Names

let (/) = Filename.concat

(** {1 Layout root} *)

type root =
  | Logical of DirPath.t
  | Physical of CUnix.physical_path

let root_path = function
  | Physical physical -> physical
  | Logical logical ->
     match Loadpath.find_with_logical_path logical with
     | [] -> CErrors.user_err (Pp.(str "No LoadPath found for " ++ DirPath.print logical ++ str "."))
     | loadpath :: _ ->
        (* TODO: Warn on ambiguous load paths? *)
        Loadpath.physical loadpath

let current_root () =
  let library_path = Libnames.pop_dirpath (Lib.library_dp ()) in
  let is_toplevel = DirPath.is_empty library_path in
  if is_toplevel then
    Physical (Sys.getcwd ())
  else
    Logical library_path

let resolve root file =
  match root with
  | Physical physical ->
     let path = physical / file in
     if Sys.file_exists path then
       path
     else
       CErrors.user_err (Pp.(str "File " ++ str file ++ str " not found in " ++ str physical))
  | Logical logical ->
     Loadpath.find_extra_dep_with_logical_path ~from:logical ~file ()

let path root file =
  root_path root / file

(** {1 Layouts} *)

type t =
  { root     : CUnix.physical_path;
    build    : CUnix.physical_path;
    snippets : CUnix.physical_path;
    modules  : CUnix.physical_path;
    ppx      : CUnix.physical_path
  }

let of_root root =
  let root = root_path root in
  let build = root / ".camltac" in
  { root;
    build;
    snippets = build / "snippets";
    modules  = build / "modules";
    ppx      = build / "ppx";
  }

let ensure_exists layout =
  let mkdir dir =
    try Sys.mkdir dir 0o700
    with Sys_error _ when Sys.file_exists dir -> ()
  in
  mkdir layout.build;
  mkdir layout.snippets;
  mkdir layout.modules;
  mkdir layout.ppx

let current () =
  let layout = of_root (current_root ()) in
  ensure_exists layout;
  layout

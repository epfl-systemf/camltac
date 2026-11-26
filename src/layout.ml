(** Layout of build directories. *)

let (/) = Filename.concat

(** {1 Layouts} *)

type t =
  { root     : CUnix.physical_path;
    build    : CUnix.physical_path;
    snippets : CUnix.physical_path;
    modules  : CUnix.physical_path;
    ppx      : CUnix.physical_path
  }

let camltac_dir = ".camltac"

let of_root root =
  let build = root / camltac_dir in
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

(** {2 Current layout} *)

let current_root () =
  let library_path = Libnames.pop_dirpath (Lib.library_dp ()) in
  let is_toplevel = Names.DirPath.is_empty library_path in
  if is_toplevel then
    Sys.getcwd ()
  else
    match Loadpath.find_with_logical_path library_path with
    | [] -> CErrors.user_err (Pp.(str "No LoadPath found for " ++ Names.DirPath.print library_path ++ str "."))
    | loadpath :: _ ->
       (* TODO: Warn on ambiguous load paths? *)
       Loadpath.physical loadpath

let current () =
  let layout = of_root (current_root ()) in
  ensure_exists layout;
  layout

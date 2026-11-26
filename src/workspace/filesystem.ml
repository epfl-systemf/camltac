(** Utilities for interacting with the file system. *)

(** {1 Paths} *)

module Path = struct
  type t = CUnix.physical_path

  let (/) = Filename.concat

  let remove_extensions basename =
    match String.index_opt basename '.' with
    | Some i -> String.sub basename 0 i
    | None   -> basename

  let module_name filename =
    (* TODO: Support UTF-8 capitalization. *)
    Filename.basename filename
    |> remove_extensions
    |> String.capitalize_ascii

  let relativize_if_under ~dir filename =
    let prefix = dir ^ Filename.dir_sep in
    if String.starts_with ~prefix filename then
      let n = String.length prefix in
      String.sub filename n (String.length filename - n)
    else
      filename
end

(** {1 Files} *)

let read filename =
  try In_channel.with_open_text filename In_channel.input_all
  with Sys_error _ when not (Sys.file_exists filename) ->
    raise Not_found

let read_or_error ~loc filename =
  try read filename
  with Not_found ->
    CErrors.user_err ~loc (Pp.(str "File " ++ str filename ++ str " does not exist."))

let write ~file contents =
  Out_channel.with_open_text file (fun oc -> output_string oc contents)

(** {1 Directories} *)

let rec mkdir ?(p = false) dir =
  if not (Sys.file_exists dir) then begin
    if p then mkdir ~p (Filename.dirname dir);
    try Sys.mkdir dir 0o700
    with Sys_error _ when Sys.file_exists dir -> ()
  end

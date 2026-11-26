(** Editor support. *)

(** {1 Merlin files} *)

let directive name value = name ^ " " ^ value

let merlin_file_contents ~(args: Compilation_args.t) =
  let packages = List.sort_uniq String.compare (args.packages @ ["ppx_rocq"]) in
  let flags =
    List.concat_map (fun m -> ["-open"; m]) args.open_modules
    @ (match args.pp with
       | Some pp -> ["-pp"; pp]
       | None    -> [])
    @ args.extras
  in
  List.map (directive "PKG") packages
  @ List.map (directive "B") args.include_dirs
  @ List.map (directive "S") args.include_dirs
  @ (match flags with
     | [] -> []
     | _  -> [directive "FLG" (String.concat " " (List.map Filename.quote flags))])
  |> String.concat "\n"

let create_merlin_file ~workspace ~args (source: Source_file.t) =
  let contents = merlin_file_contents ~args in
  let _ = Source_file.create_companion ~workspace ~name:".merlin" source contents in
  ()

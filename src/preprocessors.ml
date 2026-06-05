(** Support for build directives related to preprocessors. *)

let combine preprocessors =
  match preprocessors with
  | [] -> Ok "ppx_rocq"
  | _ ->
     let ppx_ml_main = Build_files.save_ppx_driver {|let () = Ppxlib.Driver.standalone ()|} in
     let out = Filename.remove_extension ppx_ml_main ^ ".exe" in
     Ocamlfind.compile
       ~packages:(["ppxlib"; "ppx_rocq"] @ preprocessors)
       ~linkpkg:true
       (* Using [linkpkg] is not enough, so we explicitly link. *)
       ~extra_args:(List.map Ocamlfind.find_library_cma ("ppx_rocq" :: preprocessors))
       ~out
       ppx_ml_main

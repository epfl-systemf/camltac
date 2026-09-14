(** Support for build directives related to preprocessors. *)

let combine preprocessors =
  match preprocessors with
  | [] -> Ok "ppx_rocq"
  | _ ->
     let ppx_ml_main = Build_files.write_ppx_driver {|let () = Ppxlib.Driver.standalone ()|} in
     let result =
       Ocamlfind.compile_exe
         ~packages:(["ppxlib"; "ppx_rocq"] @ preprocessors)
         ~linkpkg:true
         ~linkall:true
         ~extra_args:["-predicates"; "ppx_driver"]
         ppx_ml_main
     in
     Result.map Build_files.locate result

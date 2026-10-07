(** Support for build directives related to preprocessors. *)

let combine preprocessors =
  match preprocessors with
  | [] -> Ok "ppx_rocq"
  | _ ->
     let ppx_ml_main = Build_file.(write ~kind:Ppx_driver {|let () = Ppxlib.Driver.standalone ()|}) in
     let result =
       Ocamlfind.ocamlc
         ~packages:(["ppxlib"; "ppx_rocq"] @ preprocessors)
         ~extra_args:["-predicates"; "ppx_driver"]
         Ocamlfind.(Executable { linkpkg = true; linkall = true })
         ppx_ml_main
     in
     Result.map Build_file.locate result

(** OCaml package management. *)

(** {1 Package management} *)

val package_exists : string -> (unit, string option) result
(** [package_exists name] returns [Ok ()] if [name] is an installed
    package, or [Error name'] with the closest match otherwise. *)

(** {1 Package properties}

    Package properties are read from META files using {!Findlib}. *)

val ppx_runtime_deps : string -> string list
(** [ppx_runtime_deps ppx] returns the runtime dependencies of the [ppx]
    preprocessor. Runtime dependencies are read from either the
    [ppx_runtime_deps] or [requires(custom_ppx)] properties. *)

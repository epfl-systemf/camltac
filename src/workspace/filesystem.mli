(** Utilities for interacting with the file system. *)

(** {1 Paths} *)

module Path : sig
  type t = CUnix.physical_path
  (** A path on the filesystem. *)

  val (/) : t -> t -> t
  (** [path1 / path2] concatenates [path1] with [path2] using
      {!Filename.concat}. *)

  val module_name : t -> string
  (** [module_name path] return the OCaml module name of the given
      path. *)

  val relativize_if_under : dir:t -> t -> t
  (** [relativize_if_under ~dir path] relativizes [path] relative to
      [dir] if [dir] is a prefix of [path]. Otherwise, [path] is
      returned unchanged. *)
end

(** {1 Files} *)

val read : Path.t -> string
(** [read filename] returns the contents of the given file.

    @raise Not_found if [filename] does not correspond to a file. *)

val read_or_error : loc:Loc.t -> Path.t -> string
(** [read_or_error ~loc filename] reads the contents of [filename], or
    raises using [CErrors.user_error ~loc]. *)

val write : file:Path.t -> string -> unit
(** [write ~file contents] writes the given [contents] to [file],
    creating it if it does not exist, or overwriting its previous
    content. *)

(** {1 Directories} *)

val mkdir : ?p:bool -> Path.t -> unit
(** [mkdir ?p dir] creates the directory [dir]. If [p] is [true], parent
    directories are also created. *)

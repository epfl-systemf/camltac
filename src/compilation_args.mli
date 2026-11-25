(** Compilation arguments. *)

(** {1 Compilation arguments} *)

(** Type of compilation arguments. *)
type t = private
  { packages     : string list;   (** Packages to link ([-package]). *)
    include_dirs : string list;   (** Directories to include ([-I]). *)
    open_modules : string list;   (** Modules to open ([-open]). *)
    pp           : string option; (** Preprocessor to run ([-pp]). *)
    extras       : string list;   (** Extra options. *)
  }

val empty : t
(** Empty compilation arguments. *)

(** {2 Adding arguments} *)

val add_packages : string list -> t -> t
(** [add_packages packages args] adds [packages] to [args.packages]. *)

val add_include_dirs : string list -> t -> t
(** [add_include_dirs dirs args] adds [dirs] to [args.include_dirs]. *)

val add_open_modules : string list -> t -> t
(** [add_open_modules mods args] adds [mods] to [args.open_modules]. *)

val add_pp : string option -> t -> t
(** [add_pp pp] sets the [-pp] option of [args] to [pp]. *)

val add_extras : string list -> t -> t
(** [add_extras extras] adds [extras] to [args.extras]. *)

(** Compilation arguments. *)

(** {1 Compilation arguments} *)

type t =
  { packages     : string list;
    include_dirs : string list;
    open_modules : string list;
    pp           : string option;
    extras       : string list;
  }

let empty =
  { packages     = [];
    include_dirs = [];
    open_modules = [];
    pp           = None;
    extras       = [];
  }

(** {2 Adding arguments} *)

let dedup list =
  List.sort_uniq String.compare list

let add_packages packages args =
  { args with packages = dedup (packages @ args.packages) }

let add_include_dirs dirs args =
  { args with include_dirs = dedup (dirs @ args.include_dirs) }

let add_open_modules mods args =
  { args with open_modules = args.open_modules @ mods }

let add_pp pp args =
  { args with pp }

let add_extras extras args =
  { args with extras = args.extras @ extras }

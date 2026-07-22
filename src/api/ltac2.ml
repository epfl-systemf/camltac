(** Ltac2 FFI and APIs *)

open Ltac2_plugin

(** {1 Ltac2 FFI} *)

module FFI = struct
  include Tac2ffi
  include Tac2externals

  let define name spec f =
    let full_name = Tac2expr.{ mltac_plugin = "camltac.plugin.runtime"; mltac_tactic = name } in
    Tac2externals.define full_name spec f
end

(** {1 Ltac2 APIs} *)

(** The Ltac2 APIs are provided by MLtac2. We simply include them
    here. *)

include Mltac2.Ltac2
include Std

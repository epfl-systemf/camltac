(** Ltac2 FFI and APIs. *)

open Ltac2_plugin

(** {1 Ltac2 FFI} *)

module FFI : sig
  include module type of Tac2ffi
  include module type of Tac2externals

  val define : string -> ('a, 'f) spec -> 'f -> unit
end

(** {1 Ltac2 API} *)

(** The Ltac2 module is provided in {!Tac2api}. *)

include module type of Mltac2.Ltac2
include module type of Std

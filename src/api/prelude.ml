(** Prelude implicitly open in Camltac snippets. *)

(** This file regroups various definitions, types and modules that are
    made available in Camltac snippets. These include:

    - Syntax for describing tactics: [let*], [return], tacticals such
      as [>>] and [repeat], etc.
    - Standard tactics from Ltac2 ([Ltac2.Std]).
    - Ltac2 APIs.
 *)

include Tactics
include Ltac2.Std
module FFI = Ltac2.FFI
include Terms.Definitions

type valexpr = Ltac2_plugin.Tac2val.valexpr

(** Shadow the standard OCaml library to mark some functions as unsafe or not
    working as intended. *)
module Stdlib : sig
  include module type of Stdlib

  val stdin  : in_channel  [@@alert camltac_io "stdin does not work in Camltac."]
  val stdout : out_channel [@@alert camltac_io "stdout does not lead to correct output; use Feedback instead."]
  val stderr : out_channel [@@alert camltac_io "stderr does not lead to correct ouput; use CErrors instead."]

  val print_char : char -> unit [@@alert camltac_io "Using print_char is a mistake; use Feedback instead."]
  val print_string : string -> unit [@@alert camltac_io "Using print_string is a mistake; use Feedback instead."]
  val print_bytes : bytes -> unit [@@alert camltac_io "Using print_bytes is a mistake; use Feedback instead."]
  val print_int : int -> unit [@@alert camltac_io "Using print_int is a mistake; use Feedback instead."]
  val print_float : float -> unit [@@alert camltac_io "Using print_float is a mistake; use Feedback instead."]
  val print_endline : string -> unit [@@alert camltac_io "Using print_endline is a mistake; use Feedback instead."]
  val print_newline : unit -> unit [@@alert camltac_io "Using print_newline is a mistake; use Feedback instead."]

  val prerr_char : char -> unit [@@alert camltac_io "Using prerr_char is a mistake; use CErrors instead."]
  val prerr_string : string -> unit [@@alert camltac_io "Using prerr_string is a mistake; use CErrors instead."]
  val prerr_bytes : bytes -> unit [@@alert camltac_io "Using prerr_bytes is a mistake; use CErrors instead."]
  val prerr_int : int -> unit [@@alert camltac_io "Using prerr_int is a mistake; use CErrors instead."]
  val prerr_float : float -> unit [@@alert camltac_io "Using prerr_float is a mistake; use CErrors instead."]
  val prerr_endline : string -> unit [@@alert camltac_io "Using prerr_endline is a mistake; use CErrors instead."]
  val prerr_newline : unit -> unit [@@alert camltac_io "Using prerr_newline is a mistake; use CErrors instead."]

  val read_line : unit -> string [@@alert camltac_io "read_line does not work in Camltac."]
  val read_int_opt : unit -> int option [@@alert camltac_io "read_int_opt does not work in Camltac."]
  val read_int : unit -> int [@@alert camltac_io "read_int does not work in Camltac."]
  val read_float_opt : unit -> float option [@@alert camltac_io "read_float_opt does not work in Camltac."]
  val read_float : unit -> float [@@alert camltac_io "read_float does not work in Camltac."]

  val ref : 'a -> 'a ref [@@alert camltac_ref "Using ref at the top-level is most likely a mistake; use Summary.ref instead or stdlib_ref if you're sure of what you're doing."]
  val stdlib_ref : 'a -> 'a ref
end = struct
  include Stdlib
  let stdlib_ref = ref
end

open Names

(** Manipulation of hint databases.

    Hint databases are collections of hints used by proof search tactics such as
    [auto], [eauto], or [typeclasses eauto].

    @see <https://rocq-prover.org/doc/master/refman/proofs/automatic-tactics/auto.html#hint-databases>
      Reference Manual, "Hint databases"
 *)

(** {1 Hints} *)

(** A classification of hints according to the tactic that is performed when the
    hint is applied. *)
type 'a hint_kind =
  | Apply of 'a
  | EApply of 'a
  | Exact of 'a
  | Immediate of 'a
  | Unfold of Evaluable.t
  | Extern of Pattern.constr_pattern option * Gentactic.glob_generic_tactic

module Hint : sig
  type t
  (** Type of hints. *)

  val run : t -> (Hints.hint hint_kind -> 'a Proofview.tactic) -> 'a Proofview.tactic
  (** [run hint t] runs tactic [t] on [hint]. *)

  val pattern : t -> Pattern.constr_pattern option
  (** [pattern hint] returns the pattern that the conclusion of the goal must
      match for the hint to be applicable.

      Patterns can be specified in the [Hint Extern] and [Hint Resolve]
      vernacular commands. *)

  val cost : t -> int
  (** [cost hint] returns the cost of the hint, as either specified by the user,
      or the default value. *)

  val name : t -> GlobRef.t option
  (** [name hint] returns the name of the hint, if any.

      Hints registered through [Hint Extern] do not get a name. *)

  val database : t -> string option
  (** [database hint] returns the name of the database associated to the hint. *)

  val print : t -> Pp.t Proofview.tactic
  (** [print hint] prints the hint in the current environment. *)
end

(** {1 Hint databases} *)

type t
(** Type of hint databases. *)

val create : ?local:bool -> ?discriminated:bool -> string -> t
(** [create ?local ?discriminated name] creates a new empty hint database with
    the given name.

    @param local
      If true, the hint database is local to the current module.
      Defaults to [false].

    @param discriminated
      If true, the hint database uses a discrimination net
      to improve performance. Defaults to [true].
 *)

val discriminated : t -> bool
(** [discriminated db] returns [true] if the database uses a discrimination
    net. *)

val transparent_state : t -> TransparentState.t
(** [transparent_state db] returns the transparency state of the database. *)

val set_transparent_state : TransparentState.t -> t -> t
(** [set_transparent_state state db] sets the transparency state of the
    database.

    Previous calls to [set_opaque] are overriden by this function.
 *)

val is_opaque : Constant.t -> t -> bool
(** [is_opaque c db] returns [true] if the constant [c] is marked as opaque
    in the database.

    Opaque constants are not unfolded during proof search, which may improve
    performance (fewer unfoldings) at the cost of preventing some hints from
    matching.

    @see <https://rocq-prover.org/doc/master/refman/proofs/automatic-tactics/auto.html#rocq:cmd.Hint-Transparent>
      Reference manual, "Hint Opaque"
 *)

val set_opaque : Constant.t -> opaque:bool -> t -> t
(** [set_opaque c ~opaque db] sets the transparency of the constant in
    the hint database.

    If [opaque] is [true], [c] becomes opaque, so that the constant is no longer
    unfolded in the conclusion of the goal when matching hints.

    If [opaque] is [false], [c] is transparently unfolded during unification.

    @see <https://rocq-prover.org/doc/master/refman/proofs/automatic-tactics/auto.html#rocq:cmd.Hint-Transparent>
      Reference manual, "Hint Opaque"
 *)

val name : t -> string
(** [name db] returns the name of the hint database. *)

(** {2 Querying hints} *)

val all_hints : t -> Hint.t list
(** [all_hints db] returns the list of all hints of the database. *)

(*
  val hints_without_pattern : t -> Hint.t list
  (** [hints_without_pattern db] returns the list of all hints of the database which have no pattern. *)

  val hints_referencing : GlobRef.t -> t -> Hint.t list
(** [hints_referencing glob_ref db] returns the list of all hints associated to
    the reference in the database [db]. *)
                                          *)

(** {2 Adding or removing hints} *)

val hint_resolve : ?locality:Hints.hint_locality -> ?cost:int -> ?pattern:(Id.Set.t * Pattern.constr_pattern) -> GlobRef.t -> t -> t
(** [hint_resolve ?locality ?cost ?pattern qualid db] behaves like the vernacular
    {v [locality] Hint Resolve qualid | cost pattern : db. v}

    @param locality
      Locality of the hint (local, global, export).

    @param cost
      Cost of the tactic. A lower cost will have higher priority and
      thus will be tried more frequently.

    @param pattern
      Pattern that must be matched for the hint to apply.

    @param qualid
      The qualified name of the definition to resolve.

    @param db
      Hint database to add the hint to.
 *)


val hint_extern : ?locality:Hints.hint_locality -> cost:int -> ?pattern:(Id.Set.t * Pattern.constr_pattern) -> Gentactic.glob_generic_tactic -> t -> t
(** [hint_extern ?locality ~cost ?pattern tac db] behaves like the vernacular
    {v [locality] Hint Extern cost pattern => tactic : db v. v}

    @param locality
      Locality of the hint (local, global, export).

    @param cost
      Cost of the tactic. A lower cost will have higher priority and
      thus will be tried more frequently.

    @param pattern
      Pattern that must be matched for the hint to apply.

    @param tac
      Tactic to perform when the optional pattern is matched.

    @param db
      Hint database to add the hint to.

    @see <https://rocq-prover.org/doc/master/refman/proofs/automatic-tactics/auto.html#rocq:cmd.Hint-Extern>
      Reference Manual, "Hint Extern"
 *)

val hint_cut : ?locality:Hints.hint_locality -> Hints.hints_path -> t -> t
(** [hint_cut ?locality regex db] behaves like the vernacular
    {v [locality] Hint Cut [ regex ] : db. v}

    @param locality
      Locality of the hint (local, global, export).

    @param regex
      Regex to add to the cut expression of the database.

    @param db
      Hint database to add the hint to.

    @see <https://rocq-prover.org/doc/master/refman/proofs/automatic-tactics/auto.html#rocq:cmd.Hint-Cut>
      Reference Manual, "Hint Cut"
 *)

val hint_modes : ?locality:Hints.hint_locality -> GlobRef.t -> modes:string -> t -> t
(** [hint_modes ?locality qualid ~modes db] behaves like the vernacular command
    {v [locality] Hint Mode qualid modes : db v}

    @param locality
      Locality of the hint (local, global, export).

    @param qualid
      Identifier to set the modes for.

    @param modes
      Modes of resolution of the identifier.

    @param db
      Hint database to add the hint to.

    @see <https://rocq-prover.org/doc/master/refman/proofs/automatic-tactics/auto.html#rocq:cmd.Hint-Mode>
      Reference Manual, "Hint Mode"
 *)

val get_modes : Environ.env -> GlobRef.t -> t -> Hints.hint_mode list list
(** [get_modes env qualid db] returns the list of mode declarations of [qualid] in
    database [db]. *)

val hint_unfold : ?locality:Libobject.locality -> Names.GlobRef.t list -> t -> t
(** [hint_unfold ?locality qualids db] behaves like the vernacular command
    {v [locality] Hint Unfold qualids : db. v}

    @param locality
      Locality of the hint (local, global, export).

    @param qualids
      List of identifiers to unfold.

    @param db
      Hint database to add the hint to.

    @see <https://rocq-prover.org/doc/master/refman/proofs/automatic-tactics/auto.html#rocq:cmd.Hint-Unfold>
      Reference Manual, "Hint Unfold"
 *)

val remove_hints : ?locality:Libobject.locality -> Names.GlobRef.t list -> t -> t
(** [remove_hints ~locality qualids db] removes hints associated to [qualids] in
    database [db]. *)

(** {2 Printing} *)

val print : t -> Pp.t Proofview.tactic
(** [print db] prints all entries of the hint database in the current
    environment. *)

val print_reference : GlobRef.t -> Pp.t Proofview.tactic
(** [print_reference glob_ref] prints all entries from all hints databases that
    mention the given qualified name. *)

(** {2 Database registry} *)

val get_db : string -> t
(** [get_db name] returns the database with the given name.

    @raise Not_found if no such database with the given name exist. *)

val databases : unit -> t list
(** [databases ()] returns the list of registered databases. *)

(** {3 Databases defined in the Rocq standard library} *)

val core : unit -> t
(** A special database that is automatically used by [auto]. *)

val arith : unit -> t
(** Database containing lemmas about Peano's arithmetic. *)

val zarith : unit -> t
(** Database containing lemmas about binary signed integers. *)

val bool : unit -> t
(** Database containing lemmas about booleans. *)

val datatypes : unit -> t
(** Database containing lemmas about lists, streams, etc. *)

val sets : unit -> t
(** Database containing lemmas about sets and relations. *)

val typeclass_instances : unit -> t
(** A special database containing all typeclass instances declared in the
    environment. *)

val fset : unit -> t
(** Internal database for the implementation of the FSets library. *)

val ordered_type : unit -> t
(** Database containing lemmas about ordered types, mainly used in the FSets and
    FMaps libraries. *)

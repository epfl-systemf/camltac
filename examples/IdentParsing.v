(*|
==================
Identifier parsing
==================

Several projects such as Koika use a trick from C. Pit-Claudel and T. Bourgeat (CoqPL 21)
for converting unbound Rocq identifiers to Rocq strings. Implementing it naively in Ltac2
is very slow, and therefore one has to resort to a lookup table to get decent performance.
|*)

From Corelib Require Import Init.Byte.
From Stdlib Require Import NArith.NArith Strings.String Ascii List.
From Ltac2 Require Import Ltac2 Init Notations.
Open Scope list.

Ltac2 compute c :=
  Std.eval_vm None c.

Module Unsafe.
  Module U := Ltac2.Constr.Unsafe.

  Ltac2 string_to_coq_list type coq_of_char s :=
    let cons := constr:(@cons) in
    let rec to_list acc pos :=
        match Int.equal pos 0 with
        | true => acc
        | false =>
          let pos := Int.sub pos 1 in
          let b := coq_of_char (String.get s pos) in
          to_list (U.make (U.App cons [| type; b; acc |])) pos
        end in
    match U.check (to_list constr:(@List.nil $type) (String.length s)) with
    | Val v => v
    | Err exn => Control.throw exn
    end.

  Ltac2 coq_string_of_string' coq_string_of_coq_list type coq_of_char s :=
    let bs := string_to_coq_list type coq_of_char s in
    compute constr:($coq_string_of_coq_list $bs).
End Unsafe.

Import Unsafe.

(*|
Here's the implementation of the lookup table:
|*)

Module LookupTable.
  (* char → int →[O(1)] byte *)

  Ltac2 bytes_table () :=
    [| constr:(x00); constr:(x01); constr:(x02); constr:(x03)
     ; constr:(x04); constr:(x05); constr:(x06); constr:(x07)
     ; constr:(x08); constr:(x09); constr:(x0a); constr:(x0b)
     ; constr:(x0c); constr:(x0d); constr:(x0e); constr:(x0f)
     ; constr:(x10); constr:(x11); constr:(x12); constr:(x13)
     ; constr:(x14); constr:(x15); constr:(x16); constr:(x17)
     ; constr:(x18); constr:(x19); constr:(x1a); constr:(x1b)
     ; constr:(x1c); constr:(x1d); constr:(x1e); constr:(x1f)
     ; constr:(x20); constr:(x21); constr:(x22); constr:(x23)
     ; constr:(x24); constr:(x25); constr:(x26); constr:(x27)
     ; constr:(x28); constr:(x29); constr:(x2a); constr:(x2b)
     ; constr:(x2c); constr:(x2d); constr:(x2e); constr:(x2f)
     ; constr:(x30); constr:(x31); constr:(x32); constr:(x33)
     ; constr:(x34); constr:(x35); constr:(x36); constr:(x37)
     ; constr:(x38); constr:(x39); constr:(x3a); constr:(x3b)
     ; constr:(x3c); constr:(x3d); constr:(x3e); constr:(x3f)
     ; constr:(x40); constr:(x41); constr:(x42); constr:(x43)
     ; constr:(x44); constr:(x45); constr:(x46); constr:(x47)
     ; constr:(x48); constr:(x49); constr:(x4a); constr:(x4b)
     ; constr:(x4c); constr:(x4d); constr:(x4e); constr:(x4f)
     ; constr:(x50); constr:(x51); constr:(x52); constr:(x53)
     ; constr:(x54); constr:(x55); constr:(x56); constr:(x57)
     ; constr:(x58); constr:(x59); constr:(x5a); constr:(x5b)
     ; constr:(x5c); constr:(x5d); constr:(x5e); constr:(x5f)
     ; constr:(x60); constr:(x61); constr:(x62); constr:(x63)
     ; constr:(x64); constr:(x65); constr:(x66); constr:(x67)
     ; constr:(x68); constr:(x69); constr:(x6a); constr:(x6b)
     ; constr:(x6c); constr:(x6d); constr:(x6e); constr:(x6f)
     ; constr:(x70); constr:(x71); constr:(x72); constr:(x73)
     ; constr:(x74); constr:(x75); constr:(x76); constr:(x77)
     ; constr:(x78); constr:(x79); constr:(x7a); constr:(x7b)
     ; constr:(x7c); constr:(x7d); constr:(x7e); constr:(x7f)
     ; constr:(x80); constr:(x81); constr:(x82); constr:(x83)
     ; constr:(x84); constr:(x85); constr:(x86); constr:(x87)
     ; constr:(x88); constr:(x89); constr:(x8a); constr:(x8b)
     ; constr:(x8c); constr:(x8d); constr:(x8e); constr:(x8f)
     ; constr:(x90); constr:(x91); constr:(x92); constr:(x93)
     ; constr:(x94); constr:(x95); constr:(x96); constr:(x97)
     ; constr:(x98); constr:(x99); constr:(x9a); constr:(x9b)
     ; constr:(x9c); constr:(x9d); constr:(x9e); constr:(x9f)
     ; constr:(xa0); constr:(xa1); constr:(xa2); constr:(xa3)
     ; constr:(xa4); constr:(xa5); constr:(xa6); constr:(xa7)
     ; constr:(xa8); constr:(xa9); constr:(xaa); constr:(xab)
     ; constr:(xac); constr:(xad); constr:(xae); constr:(xaf)
     ; constr:(xb0); constr:(xb1); constr:(xb2); constr:(xb3)
     ; constr:(xb4); constr:(xb5); constr:(xb6); constr:(xb7)
     ; constr:(xb8); constr:(xb9); constr:(xba); constr:(xbb)
     ; constr:(xbc); constr:(xbd); constr:(xbe); constr:(xbf)
     ; constr:(xc0); constr:(xc1); constr:(xc2); constr:(xc3)
     ; constr:(xc4); constr:(xc5); constr:(xc6); constr:(xc7)
     ; constr:(xc8); constr:(xc9); constr:(xca); constr:(xcb)
     ; constr:(xcc); constr:(xcd); constr:(xce); constr:(xcf)
     ; constr:(xd0); constr:(xd1); constr:(xd2); constr:(xd3)
     ; constr:(xd4); constr:(xd5); constr:(xd6); constr:(xd7)
     ; constr:(xd8); constr:(xd9); constr:(xda); constr:(xdb)
     ; constr:(xdc); constr:(xdd); constr:(xde); constr:(xdf)
     ; constr:(xe0); constr:(xe1); constr:(xe2); constr:(xe3)
     ; constr:(xe4); constr:(xe5); constr:(xe6); constr:(xe7)
     ; constr:(xe8); constr:(xe9); constr:(xea); constr:(xeb)
     ; constr:(xec); constr:(xed); constr:(xee); constr:(xef)
     ; constr:(xf0); constr:(xf1); constr:(xf2); constr:(xf3)
     ; constr:(xf4); constr:(xf5); constr:(xf6); constr:(xf7)
     ; constr:(xf8); constr:(xf9); constr:(xfa); constr:(xfb)
     ; constr:(xfc); constr:(xfd); constr:(xfe); constr:(xff) |].

  Ltac2 byte_of_char bytes_table chr :=
    Array.get bytes_table (Char.to_int chr).

  Ltac2 coq_string_of_string s :=
    let table := bytes_table () in
    coq_string_of_string' constr:(string_of_list_byte) constr:(Byte.byte) (byte_of_char table) s.
End LookupTable.

Ltac2 coq_string_of_string := LookupTable.coq_string_of_string.
Ltac2 coq_string_of_ident x := LookupTable.coq_string_of_string (Ident.to_string x).

Ltac2 Type exn ::= [ NoIdentInContext ].

(* This is the original implementation, as described in the CoqPL'21 paper. *)
Definition __Ltac2_MarkedIdent (A: Type) := A.

Ltac serialize_ident_in_context :=
  ltac2:(match! goal with
         | [ h: __Ltac2_MarkedIdent _ |- _ ] =>
             let coq_string := coq_string_of_ident h in
             exact ($coq_string)
         | [  |- _ ] => Control.throw NoIdentInContext
         end).

(* `binder_to_string` is useful when converting an identifier to a string but
     also using it as an actual binder. *)
Notation binder_to_string body a :=
  (match (body: __Ltac2_MarkedIdent _) return string with
   | a => ltac:(serialize_ident_in_context)
   end) (only parsing).

Notation ident_to_string a :=
  (binder_to_string true a) (only parsing).

(*|
Let's benchmark it:
|*)

(* 1000 A *)
Time Compute (let x := ident_to_string AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA in String.length x).

(*|
Now, let's reimplement it in OCaml!
|*)

Require Import Camltac.Camltac.

Camltac Run ocaml:{{
  open Names

  let lookup_table = [|
       [%constr "x00"]; [%constr "x01"]; [%constr "x02"]; [%constr "x03"]
     ; [%constr "x04"]; [%constr "x05"]; [%constr "x06"]; [%constr "x07"]
     ; [%constr "x08"]; [%constr "x09"]; [%constr "x0a"]; [%constr "x0b"]
     ; [%constr "x0c"]; [%constr "x0d"]; [%constr "x0e"]; [%constr "x0f"]
     ; [%constr "x10"]; [%constr "x11"]; [%constr "x12"]; [%constr "x13"]
     ; [%constr "x14"]; [%constr "x15"]; [%constr "x16"]; [%constr "x17"]
     ; [%constr "x18"]; [%constr "x19"]; [%constr "x1a"]; [%constr "x1b"]
     ; [%constr "x1c"]; [%constr "x1d"]; [%constr "x1e"]; [%constr "x1f"]
     ; [%constr "x20"]; [%constr "x21"]; [%constr "x22"]; [%constr "x23"]
     ; [%constr "x24"]; [%constr "x25"]; [%constr "x26"]; [%constr "x27"]
     ; [%constr "x28"]; [%constr "x29"]; [%constr "x2a"]; [%constr "x2b"]
     ; [%constr "x2c"]; [%constr "x2d"]; [%constr "x2e"]; [%constr "x2f"]
     ; [%constr "x30"]; [%constr "x31"]; [%constr "x32"]; [%constr "x33"]
     ; [%constr "x34"]; [%constr "x35"]; [%constr "x36"]; [%constr "x37"]
     ; [%constr "x38"]; [%constr "x39"]; [%constr "x3a"]; [%constr "x3b"]
     ; [%constr "x3c"]; [%constr "x3d"]; [%constr "x3e"]; [%constr "x3f"]
     ; [%constr "x40"]; [%constr "x41"]; [%constr "x42"]; [%constr "x43"]
     ; [%constr "x44"]; [%constr "x45"]; [%constr "x46"]; [%constr "x47"]
     ; [%constr "x48"]; [%constr "x49"]; [%constr "x4a"]; [%constr "x4b"]
     ; [%constr "x4c"]; [%constr "x4d"]; [%constr "x4e"]; [%constr "x4f"]
     ; [%constr "x50"]; [%constr "x51"]; [%constr "x52"]; [%constr "x53"]
     ; [%constr "x54"]; [%constr "x55"]; [%constr "x56"]; [%constr "x57"]
     ; [%constr "x58"]; [%constr "x59"]; [%constr "x5a"]; [%constr "x5b"]
     ; [%constr "x5c"]; [%constr "x5d"]; [%constr "x5e"]; [%constr "x5f"]
     ; [%constr "x60"]; [%constr "x61"]; [%constr "x62"]; [%constr "x63"]
     ; [%constr "x64"]; [%constr "x65"]; [%constr "x66"]; [%constr "x67"]
     ; [%constr "x68"]; [%constr "x69"]; [%constr "x6a"]; [%constr "x6b"]
     ; [%constr "x6c"]; [%constr "x6d"]; [%constr "x6e"]; [%constr "x6f"]
     ; [%constr "x70"]; [%constr "x71"]; [%constr "x72"]; [%constr "x73"]
     ; [%constr "x74"]; [%constr "x75"]; [%constr "x76"]; [%constr "x77"]
     ; [%constr "x78"]; [%constr "x79"]; [%constr "x7a"]; [%constr "x7b"]
     ; [%constr "x7c"]; [%constr "x7d"]; [%constr "x7e"]; [%constr "x7f"]
     ; [%constr "x80"]; [%constr "x81"]; [%constr "x82"]; [%constr "x83"]
     ; [%constr "x84"]; [%constr "x85"]; [%constr "x86"]; [%constr "x87"]
     ; [%constr "x88"]; [%constr "x89"]; [%constr "x8a"]; [%constr "x8b"]
     ; [%constr "x8c"]; [%constr "x8d"]; [%constr "x8e"]; [%constr "x8f"]
     ; [%constr "x90"]; [%constr "x91"]; [%constr "x92"]; [%constr "x93"]
     ; [%constr "x94"]; [%constr "x95"]; [%constr "x96"]; [%constr "x97"]
     ; [%constr "x98"]; [%constr "x99"]; [%constr "x9a"]; [%constr "x9b"]
     ; [%constr "x9c"]; [%constr "x9d"]; [%constr "x9e"]; [%constr "x9f"]
     ; [%constr "xa0"]; [%constr "xa1"]; [%constr "xa2"]; [%constr "xa3"]
     ; [%constr "xa4"]; [%constr "xa5"]; [%constr "xa6"]; [%constr "xa7"]
     ; [%constr "xa8"]; [%constr "xa9"]; [%constr "xaa"]; [%constr "xab"]
     ; [%constr "xac"]; [%constr "xad"]; [%constr "xae"]; [%constr "xaf"]
     ; [%constr "xb0"]; [%constr "xb1"]; [%constr "xb2"]; [%constr "xb3"]
     ; [%constr "xb4"]; [%constr "xb5"]; [%constr "xb6"]; [%constr "xb7"]
     ; [%constr "xb8"]; [%constr "xb9"]; [%constr "xba"]; [%constr "xbb"]
     ; [%constr "xbc"]; [%constr "xbd"]; [%constr "xbe"]; [%constr "xbf"]
     ; [%constr "xc0"]; [%constr "xc1"]; [%constr "xc2"]; [%constr "xc3"]
     ; [%constr "xc4"]; [%constr "xc5"]; [%constr "xc6"]; [%constr "xc7"]
     ; [%constr "xc8"]; [%constr "xc9"]; [%constr "xca"]; [%constr "xcb"]
     ; [%constr "xcc"]; [%constr "xcd"]; [%constr "xce"]; [%constr "xcf"]
     ; [%constr "xd0"]; [%constr "xd1"]; [%constr "xd2"]; [%constr "xd3"]
     ; [%constr "xd4"]; [%constr "xd5"]; [%constr "xd6"]; [%constr "xd7"]
     ; [%constr "xd8"]; [%constr "xd9"]; [%constr "xda"]; [%constr "xdb"]
     ; [%constr "xdc"]; [%constr "xdd"]; [%constr "xde"]; [%constr "xdf"]
     ; [%constr "xe0"]; [%constr "xe1"]; [%constr "xe2"]; [%constr "xe3"]
     ; [%constr "xe4"]; [%constr "xe5"]; [%constr "xe6"]; [%constr "xe7"]
     ; [%constr "xe8"]; [%constr "xe9"]; [%constr "xea"]; [%constr "xeb"]
     ; [%constr "xec"]; [%constr "xed"]; [%constr "xee"]; [%constr "xef"]
     ; [%constr "xf0"]; [%constr "xf1"]; [%constr "xf2"]; [%constr "xf3"]
     ; [%constr "xf4"]; [%constr "xf5"]; [%constr "xf6"]; [%constr "xf7"]
     ; [%constr "xf8"]; [%constr "xf9"]; [%constr "xfa"]; [%constr "xfb"]
     ; [%constr "xfc"]; [%constr "xfd"]; [%constr "xfe"]; [%constr "xff"] |]

  let id_to_byte_list (id: Id.t) =
    String.fold_right (fun c tail ->
        let* tail in
        let* byte = lookup_table.(Char.code c) in
        [%constr "%{byte} :: %{tail}"])
    (Id.to_string id) [%constr "@nil Byte.byte"]

  let id_to_rocq_string (id: Id.t) =
    let* bytes = id_to_byte_list id in
    let* id = [%constr "string_of_list_byte %{bytes}"] in
    Ltac2.eval (Ltac2.Red.native None) id

  let serialize_binder_in_context =
    let open Proofview in
    Goal.enter begin fun gl ->
      let hyps = Goal.hyps gl in
      match hyps with
      | [LocalDef (binder, _, _)] ->
        let* rocq_string = id_to_rocq_string (binder.binder_name) in
        Ltac2.exact_no_check rocq_string
      | _ -> assert false
    end

  let () = Runtime.Registry.register "id_to_rocq_string" id_to_rocq_string
  let () = Runtime.Registry.register "serialize_binder_in_context" serialize_binder_in_context
}}.

Notation ml_ident_to_string a :=
  (match true return string with
   | a => ocaml:{{Runtime.Registry.find "serialize_binder_in_context"}}
   end) (only parsing). 

(*|
Here are the results:
|*)

(* 1000 A *)
Time Compute (let x := ml_ident_to_string AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA in String.length x).

(** Contextual arguments to the compiler. *)

(** {1 Compilation state} *)

type state =
  { modules      : Build_file.t CString.Map.t;
    packages     : CString.Set.t;
    modules_dirs : CString.Set.t;
    alias_module : alias_module;
  }

and alias_module = Empty | Stale | Ready of Build_file.t

let empty_state =
  { modules      = CString.Map.empty;
    packages     = CString.Set.empty;
    modules_dirs = CString.Set.empty;
    alias_module = Empty
  }

(** {2 Summary state}

    This state follows backtracking. *)

[%%if rocq >= (9, 4)]
open Summary.Ref
[%%endif]

let state =
  Summary.ref
    ~stage:Synterp
    ~name:"Camltac:compilation_state"
    empty_state

let add_module (name, Compiler.{ file; packages }) =
  let old_state = !state in
  state :=
    { modules      = (match name with
                     | Some name -> CString.Map.add name file old_state.modules
                     | None -> old_state.modules);
      packages     = CString.Set.add_seq (List.to_seq packages) old_state.packages;
      modules_dirs = CString.Set.add ((Build_file.layout file).modules) old_state.modules_dirs;
      alias_module = match name with
                     | Some _ -> Stale
                     | None -> old_state.alias_module
    }

(** {2 Libobject}

    Module declaration is recorded in [Libobject], so that it can be replayed
    upon [Require]/[Import]. *)

let module_object : Libobject.locality * (string option * Compiler.compiled) -> Libobject.obj =
  let open Libobject in
  declare_object
    (object_with_locality
      "camltac-declared-module"
      ~stage:Synterp
      ~cache:add_module
      ~subst:None
      ~discharge:(fun x -> x))

(** Check that a module doesn't already have this name. *)
let check_module_name = function
  | Some (name, loc) when CString.Map.mem name !state.modules  ->
     CErrors.user_err ~loc (Pp.(str "Module " ++ str name ++ str " is already defined."))
  | Some (name, _) -> Some name
  | None -> None

let declare_module ~locality ~name out =
  let name = check_module_name name in
  Lib.add_leaf (module_object (locality, (name, out)))

(** {2 Alias module} *)

module Alias_module = struct
  let alias_statement (name, file) =
    let mangled_name = Build_file.module_name file in
    Format.sprintf "module %s = %s" name mangled_name

  let contents state =
    CString.Map.bindings state.modules
    |> List.map alias_statement
    |> String.concat "\n"

  let generate state =
    let source = Build_file.write ~kind:Build_file.Module (contents state) in
    let out =
      Ocamlfind.ocamlc
        ~include_dirs:(CString.Set.elements state.modules_dirs)
        ~extra_args:["-no-alias-deps"]
        Ocamlfind.Compile_only
        source
    in
    match out with
    | Ok file -> file
    | Error code ->
       CErrors.user_err (Pp.(str "Compilation of alias module failed with error " ++ int code ++ str "."))
end

(** {2 Current state}

    As an optimization, alias modules are regenerated only when [current_state]
    is called, instead of eagerly in [declare_module]. This laziness is useful
    in the case when many modules are declared without a new compilation, which
    would trigger [N] successive calls to the compiler for no reason.
 *)

let current_state () =
  let s = !state in
  match s.alias_module with
  | Stale ->
     let s = { s with alias_module = Ready (Alias_module.generate s) } in
     state := s;
     s
  | _ ->
     s

(** {1 Compilation context} *)

type t = Compiler.args =
  { packages     : string list; (** List of packages to link ([-package]). *)
    include_dirs : string list; (** List of directories to include ([-I]). *)
    open_modules : string list; (** List of modules to open ([-open]. *)
  }

let default =
  { packages     = ["camltac.plugin.runtime"; "camltac.plugin.api"; "ppx_rocq.runtime"];
    include_dirs = [];
    open_modules = ["Api"; "Prelude"]
  }

let of_state (state: state) =
  { packages     = CString.Set.elements state.packages @ default.packages;
    include_dirs = CString.Set.elements state.modules_dirs @ default.include_dirs;
    open_modules = match state.alias_module with
                   | Empty -> default.open_modules
                   | Stale -> assert false (* By the invariants. *)
                   | Ready alias_file -> Build_file.module_name alias_file :: default.open_modules
  }

let current () = of_state (current_state ())

(** Pipelines. *)

(** {1 Pipelines} *)

type ('a, 'b) t = 'a -> 'b
type 'a middleware = ('a, 'a) t

module type PARAMS = sig
  val workspace : Workspace.t
  (** Current workspace. *)

  val file : string
  (** Name of the currently-compiling file. *)

  val args : Compilation_args.t
  (** Compilation arguments. *)

  val aliases : (string * string) list
  (** Module aliases. *)

  val loaded_units : CString.Set.t
  (** Set of loaded units. *)
end

[%%if rocq >= (9, 2)]
let poly_default = PolyFlags.default
[%%else]
let poly_default = false
[%%endif]

let parse_interface : (Compiler.Artifact.t, Interface.t) t = fun artifact ->
  Compiler.Artifact.file artifact
  |> Build_file.resolve
  |> Filesystem.read
  |> String.trim
  |> Interface.parse

let print_interface : (Interface.t, unit) t = fun intf ->
  Feedback.msg_info (Interface.print intf)

module Make (P: PARAMS) = struct
  open P

  let scaffold (kind: Scaffold.kind): (Snippet.t, string) t = fun snippet ->
    Scaffold.make kind ~aliases snippet

  let create_source_file : (string, Source_file.t) t = fun contents ->
    Source_file.create ~workspace ~file contents

  let create_merlin_file : Source_file.t middleware = fun source_file ->
    Editor_support.create_merlin_file ~workspace ~args source_file;
    source_file

  let create_build_file : (Source_file.t, Build_file.t) t = fun source_file ->
    Build_file.copy_source ~workspace ~loaded_units source_file

  let generate_file ~dir ~name : (string, Build_file.t) t = fun contents ->
    Build_file.generate ~workspace ~dir ~name contents

  let compile (mode: Compiler.mode) ~(source : Snippet.t) : (Build_file.t, Compiler.Artifact.t) t = fun build_file ->
    let result, diagnostics = Compiler.compile ~args mode build_file in
    Error_reporter.report_all ~source diagnostics;
    match result with
    | Ok artifact -> artifact
    | Error code  ->
       (* Compilation errors are reported by [Error_reporter], so this
          case cover other types of errors. *)
       CErrors.user_err ~loc:(Snippet.loc source)
         Pp.(str "Compilation failed with exit code " ++ int code)

  let declare_module ~locality ~name : Compiler.Artifact.t middleware = fun artifact ->
    Synterp.declare ~locality ~name artifact;
    artifact

  let infer_interface ~source : (Build_file.t, Compiler.Artifact.t) t =
    compile Compiler.Infer_interface ~source

  let infer_tactic_type : (Snippet.t, string) t = fun snippet ->
    scaffold Scaffold.Expression snippet
    |> create_source_file
    |> create_merlin_file
    |> create_build_file
    |> infer_interface ~source:snippet
    |> parse_interface
    |> Interface.tactic_type
    |> function
       | Ok typ    -> typ
       | Error typ -> CErrors.user_err ~loc:(Snippet.loc snippet)
           Pp.(str "Expected a value of type _ tactic but got " ++ str typ ++ str " instead.")
end

let check_module_shadowing state = function
| Some name ->
   if Interp.is_loaded name state then
     Feedback.msg_warning (Pp.(str "Module " ++ str name ++ str " shadows a previously-defined module."));
| None -> ()

let load_module ~locality ~name : (Compiler.Artifact.t, unit) t = fun artifact ->
  check_module_shadowing (Interp.current ()) name;
  Interp.load_module ~locality ~name artifact

let load_tactic : (Compiler.Artifact.t, 'a Proofview.tactic) t = fun artifact ->
  let dependencies = Compiler.Artifact.dependencies artifact in
  let file         = Compiler.Artifact.file artifact in
  Loader.load_file ~dependencies `Private file;
  Runtime.Output.get_tactic ()

let run_tactic ?(proof: Declare.Proof.t option) : ('a Proofview.tactic, 'a) t = fun tactic ->
  let env = Global.env () in
  let proof =
    match proof with
    | Some proof ->
       Declare.Proof.get proof
    | None ->
       let sigma = Evd.from_env env in
       Proof.start
         ~name:(Names.Id.of_string "CamltacEval")
         ~poly:poly_default
         sigma []
  in
  let (_, _, result) = Proof.run_tactic env tactic proof in
  result

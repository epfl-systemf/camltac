open Pp

let run_file = Runner.run_file

let run_snippet ~loc snippet =
  let scaffold = Scaffold.make ~loc snippet in
  Runner.run_snippet (Scaffold.contents scaffold)

let run_snippet_as_term ~loc snippet =
  let scaffold =
    snippet
    |> Scaffold.make ~loc
    |> Scaffold.wrap ~before:"Runtime.Registry.register_term begin" ~after:"end" in
  Runner.run_snippet (Scaffold.contents scaffold);
  Runtime.Registry.get_last_term ()

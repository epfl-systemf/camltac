open Pp

let run_file = Runner.run_file

let run_snippet snippet =
  let scaffold = Scaffold.make snippet in
  Runner.run_snippet (Scaffold.contents scaffold)

let run_snippet_as_term snippet =
  let scaffold =
    snippet
    |> Scaffold.make
    |> Scaffold.wrap ~before:"Runtime.Registry.register_output begin" ~after:"end" in
  Runner.run_snippet (Scaffold.contents scaffold);
  Runtime.Registry.get_last_output ()

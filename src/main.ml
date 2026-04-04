open Pp

let run_file = Runner.run_file

let run_snippet snippet =
  let scaffold = Scaffold.make snippet in
  Runner.run_code (Scaffold.contents scaffold)

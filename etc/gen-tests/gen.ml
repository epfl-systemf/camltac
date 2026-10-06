(* Generates the Dune rules emulating expected output tests (see tests/dune).
   Usage: gen.exe A.expected B.expected … *)

let rule name =
  Printf.printf
{|
(rule
 (targets %s.output)
 (deps %s.v (package camltac))
 (action
  (setenv OCAMLPATH %%{project_root}/../install/default/lib
   (with-stdout-to %s.output
    (run coqc -q -Q ../theories Camltac -R . Camltac.Tests %s.v)))))

(rule
 (alias runtest)
 (action (diff %s.expected %s.output)))
|} name name name name name name

let () =
  Sys.argv
  |> Array.to_list
  |> List.tl
  |> List.iter (fun file -> rule (Filename.remove_extension file))

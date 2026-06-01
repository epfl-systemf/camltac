(** Utilities for manipulating temporary files. *)

let output_dir = ".camltac"
let () =
  if not (Sys.file_exists output_dir) then Sys.mkdir output_dir 0o755

let with_content ?(prefix = "") ?(suffix = "") content =
  let temp_file = Filename.temp_file ~temp_dir:output_dir prefix suffix in
  let file_channel = Out_channel.open_text temp_file in
  Fun.protect ~finally:(fun () -> Stdlib.close_out_noerr file_channel) begin fun () ->
    Out_channel.output_string file_channel content;
    temp_file
  end

let with_temp_file ?(prefix = "") ?(suffix = "") content f =
  let temp_file = with_content ~prefix ~suffix content in
  Fun.protect ~finally:(fun () -> Sys.remove temp_file) (fun () -> f temp_file)


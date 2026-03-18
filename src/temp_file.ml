(** Utilities for manipulating temporary files. *)

let with_content ?(prefix = "") ?(suffix = "") content =
  let temp_file, file_channel = Filename.open_temp_file prefix suffix in
  Fun.protect ~finally:(fun () -> Stdlib.close_out_noerr file_channel) begin fun () ->
    Out_channel.output_string file_channel content;
    temp_file
  end

let with_temp_file ?(prefix = "") ?(suffix = "") content f =
  let temp_file = with_content ~prefix ~suffix content in
  Fun.protect ~finally:(fun () -> Sys.remove temp_file) (fun () -> f temp_file)


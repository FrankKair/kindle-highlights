open Core

let fzf_available () = Stdlib.Sys.command "command -v fzf >/dev/null 2>&1" = 0

let select_with_fzf ~prompt options =
  let input = String.concat ~sep:"\n" options in
  let cmd =
    sprintf "printf '%%s\\n' %s | fzf --prompt=%s" (Filename.quote input)
      (Filename.quote (prompt ^ " "))
  in
  let ic = Core_unix.open_process_in cmd in
  let result = In_channel.input_line ic in
  let _status = Core_unix.close_process_in ic in
  match result with Some choice -> Some (String.strip choice) | None -> None

let select ~prompt options =
  let labels = List.map options ~f:fst in
  let selected =
    if fzf_available () then select_with_fzf ~prompt labels
    else (
      eprintf "fzf is required. Please install it to browse highlights.\n";
      exit 1)
  in
  Option.bind selected ~f:(fun label ->
      List.Assoc.find options label ~equal:String.equal)

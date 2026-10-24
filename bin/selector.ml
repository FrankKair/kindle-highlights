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
  let status = Core_unix.close_process_in ic in
  match status with
  | Ok () -> Ok (Option.map result ~f:String.strip)
  | Error (`Exit_non_zero (1 | 130)) -> Ok None
  | Error _ ->
      Error
        (sprintf "Book selection failed: %s\n"
           (Core_unix.Exit_or_signal.to_string_hum status))

let select ~prompt options =
  if not (fzf_available ()) then
    Error "fzf is required. Please install it to browse highlights."
  else
    let labels = List.map options ~f:fst in
    Result.map (select_with_fzf ~prompt labels) ~f:(fun selected ->
        Option.bind selected ~f:(fun label ->
            List.Assoc.find options label ~equal:String.equal))

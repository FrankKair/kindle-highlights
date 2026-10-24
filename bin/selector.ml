open Core

let fzf_available () = Stdlib.Sys.command "command -v fzf >/dev/null 2>&1" = 0

let select_with_fzf ~prompt options =
  let path = Stdlib.Filename.temp_file "kindle-books-" ".txt" in
  Exn.protect
    ~f:(fun () ->
      Out_channel.with_file path ~f:(fun channel ->
          List.iter options ~f:(fun label -> fprintf channel "%s\n" label));
      let cmd =
        sprintf "fzf --prompt=%s < %s"
          (Filename.quote (prompt ^ " "))
          (Filename.quote path)
      in
      let ic = Core_unix.open_process_in cmd in
      let result = In_channel.input_line ic in
      let status = Core_unix.close_process_in ic in
      match status with
      | Ok () -> Ok (Option.map result ~f:String.strip)
      | Error (`Exit_non_zero (1 | 130)) -> Ok None
      | Error _ ->
          Error
            (sprintf "Book selection failed: %s"
               (Core_unix.Exit_or_signal.to_string_hum status)))
    ~finally:(fun () -> Core_unix.unlink path)

let select ~prompt options =
  if not (fzf_available ()) then
    Error "fzf is required. Please install it to browse highlights."
  else
    let labels = List.map options ~f:fst in
    Result.map (select_with_fzf ~prompt labels) ~f:(fun selected ->
        Option.bind selected ~f:(fun label ->
            List.Assoc.find options label ~equal:String.equal))

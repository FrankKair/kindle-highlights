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

let select_with_numbered_list ~prompt options =
  let indexed = List.mapi options ~f:(fun i book -> (i + 1, book)) in
  printf "\n%s\n\n" prompt;
  List.iter indexed ~f:(fun (i, book) -> printf "  %d) %s\n" i book);
  printf "\n> %!";
  match In_channel.(input_line stdin) with
  | None -> None
  | Some input -> (
      match Option.try_with (fun () -> Int.of_string (String.strip input)) with
      | Some n when n >= 1 && n <= List.length options ->
          List.nth options (n - 1)
      | _ ->
          eprintf "Invalid selection.\n";
          None)

let select ~prompt options =
  if fzf_available () then select_with_fzf ~prompt options
  else select_with_numbered_list ~prompt options

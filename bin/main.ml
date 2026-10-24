open Core
open Kindle

let library_path () =
  match Store.default_path () with
  | Ok path -> path
  | Error error ->
      eprintf "Could not locate the saved library: %s\n"
        (Store.error_to_string error);
      exit 1

let browse_entries entries =
  match Browser.browse_books (Bookshelf.of_entries entries) with
  | Ok () -> ()
  | Error message ->
      eprintf "%s\n" message;
      exit 1

let browse () =
  let path = library_path () in
  match Store.load ~path with
  | Ok entries -> browse_entries entries
  | Error Store.Missing_file ->
      eprintf
        "No saved highlights found. Run kindle_highlights load FILE first.\n";
      exit 1
  | Error error ->
      eprintf "Could not load saved highlights (%s): %s\n" path
        (Store.error_to_string error);
      exit 1

let load_and_browse filepath =
  let lines =
    try In_channel.read_lines filepath
    with Sys_error message ->
      eprintf "Could not read clippings file (%s): %s\n" filepath message;
      exit 1
  in
  let entries = Parser.parse_lines lines in
  let path = library_path () in
  match Store.save ~path entries with
  | Error error ->
      eprintf "Could not save highlights (%s): %s\n" path
        (Store.error_to_string error);
      exit 1
  | Ok () ->
      printf "Loaded %d highlights from %s.\n" (List.length entries) filepath;
      browse_entries entries

let load_command =
  Command.basic ~summary:"Replace saved highlights from a clippings file"
    Command.Let_syntax.(
      let%map_open filepath = anon ("FILE" %: string) in
      fun () -> load_and_browse filepath)

let command =
  Command.group ~summary:"Browse saved Kindle highlights"
    ~body:(fun ~path:_ -> browse ())
    [ ("load", load_command) ]

let () = Command_unix.run ~version:"0.0.1" ~build_info:"First version" command

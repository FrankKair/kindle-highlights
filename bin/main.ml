open Core
open Kindle

let print_quotes quotes = List.iter ~f:(printf "\n> %s\n") quotes

let show_bookshelf bookshelf =
  let books = Bookshelf.books bookshelf in
  match books with
  | [] -> printf "No highlights found in the saved library.\n"
  | _ -> (
      match Selector.select ~prompt:"Select a book:" books with
      | None -> printf "No book selected.\n"
      | Some book -> (
          match Bookshelf.quotes bookshelf book with
          | None -> printf "No highlights found for %s\n" book
          | Some quotes -> print_quotes quotes))

let library_path () =
  match Store.default_path () with
  | Ok path -> path
  | Error error ->
      eprintf "Could not locate the saved library: %s\n"
        (Store.error_to_string error);
      exit 1

let browse () =
  let path = library_path () in
  match Store.load ~path with
  | Ok entries -> show_bookshelf (Bookshelf.of_entries entries)
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
      show_bookshelf (Bookshelf.of_entries entries)

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

open Core
open Kindle

let print_quotes channel book quotes =
  fprintf channel "\n--- %s ---\n" book;
  List.iter quotes ~f:(fun quote -> fprintf channel "\n> %s\n" quote)

let show_quotes book quotes =
  let path = Stdlib.Filename.temp_file "kindle-quotes-" ".txt" in
  Exn.protect
    ~f:(fun () ->
      Out_channel.with_file path ~f:(fun channel ->
          print_quotes channel book quotes);
      ignore
        (Stdlib.Sys.command
           ("less -P 'q to return | / to search' -- " ^ Filename.quote path)))
    ~finally:(fun () -> Core_unix.unlink path)

let book_options bookshelf =
  let counts =
    Bookshelf.books bookshelf
    |> List.map ~f:(fun book ->
        let count =
          Bookshelf.quotes bookshelf book
          |> Option.value ~default:[] |> List.length
        in
        (book, count))
  in
  let width =
    List.fold counts ~init:1 ~f:(fun width (_, count) ->
        Int.max width (String.length (Int.to_string count)))
  in
  List.map counts ~f:(fun (book, count) ->
      (sprintf "[%*d] %s" width count book, book))

let rec browse_books bookshelf =
  match book_options bookshelf with
  | [] -> printf "No highlights found in the saved library.\n"
  | options -> (
      match Selector.select ~prompt:"Select a book:" options with
      | None -> ()
      | Some book -> (
          match Bookshelf.quotes bookshelf book with
          | None -> printf "No highlights found for %s\n" book
          | Some quotes ->
              show_quotes book quotes;
              browse_books bookshelf))

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
  | Ok entries -> browse_books (Bookshelf.of_entries entries)
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
      browse_books (Bookshelf.of_entries entries)

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

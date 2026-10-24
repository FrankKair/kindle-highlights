open Core
open Kindle

let print_quotes channel book quotes =
  fprintf channel "\n--- %s ---\n" book;
  List.iter quotes ~f:(fun quote -> fprintf channel "\n> %s\n" quote)

let show_quotes book quotes =
  let path = Stdlib.Filename.temp_file "kindle-quotes-" ".txt" in
  let status =
    Exn.protect
      ~f:(fun () ->
        Out_channel.with_file path ~f:(fun channel ->
            print_quotes channel book quotes);
        Stdlib.Sys.command
          ("less -P 'q to return | / to search' -- " ^ Filename.quote path))
      ~finally:(fun () -> Core_unix.unlink path)
  in
  if status = 0 then Ok ()
  else
    Error
      (sprintf "Could not display highlights: less exited with code %d\n" status)

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

let browse_books bookshelf =
  let rec loop options =
    match Selector.select ~prompt:"Select a book:" options with
    | Error _ as error -> error
    | Ok None -> Ok ()
    | Ok (Some book) -> (
        match Bookshelf.quotes bookshelf book with
        | None -> Error (sprintf "No highlights found for %s\n" book)
        | Some quotes -> (
            match show_quotes book quotes with
            | Ok () -> loop options
            | Error _ as error -> error))
  in
  match book_options bookshelf with
  | [] ->
      printf "No highlights found in the saved library.\n";
      Ok ()
  | options -> loop options

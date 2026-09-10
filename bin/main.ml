open Core
open Kindle

let print_quotes quotes = List.iter ~f:(printf "\n> %s\n") quotes

let run filepath =
  try
    let lines = In_channel.read_lines filepath in
    let bookshelf = Bookshelf.build_from lines in
    let books = Bookshelf.books bookshelf in
    match books with
    | [] -> printf "No highlights found in %s\n" filepath
    | _ -> (
        match Selector.select ~prompt:"Select a book:" books with
        | None -> printf "No book selected.\n"
        | Some book -> (
            match Bookshelf.quotes bookshelf book with
            | None -> printf "No highlights found for %s\n" book
            | Some quotes -> print_quotes quotes))
  with Sys_error msg ->
    eprintf "Could not read clippings file (%s): %s\n" filepath msg;
    exit 1

let command =
  Command.basic ~summary:"Reads My Clippings file and parses the highlights"
    Command.Let_syntax.(
      let%map_open filepath = anon ("filepath" %: string) in
      fun () -> run filepath)

let () = Command_unix.run ~version:"0.0.1" ~build_info:"First version" command

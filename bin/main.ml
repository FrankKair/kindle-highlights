open Core
open Parser

let prompt_for_book available_books =
  List.iter ~f:(printf "%s\n") available_books;
  print_endline "\nEnter the name of the book:";
  match In_channel.input_line In_channel.stdin with
  | None -> print_endline "No value entered. Aborting."; exit 0;
  | Some "" -> print_endline "No value entered. Aborting."; exit 0;
  | Some book -> book

let print_quotes qs book =
  Array.iter ~f:(printf "\n> %s\n") (Hashtbl.find_exn qs book)

let command =
  Command.basic
    ~summary:"Reads My Clippings file and parses the highlights"
    ~readme:(fun () -> "More detailed information")
    Command.Param.(
      map (both
            (anon ("filepath" %: string))
            (anon (maybe ("book" %: string))))
       ~f:(fun (filepath, book) ->
         (fun () ->
           let qs = Quotes.build (In_channel.read_lines filepath) in
           let available_books = Hashtbl.keys qs in
           let book = match book with
             | Some b -> b
             | None -> (prompt_for_book available_books) in
           (print_quotes qs book))))

let () =
  Command.run ~version:"1.0" ~build_info:"test" command

open Core
open Parser
open Lwt

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
               match book with
               | Some b -> (print_quotes qs b);
               | None ->
                 let selected_book =
                   Inquire.select "Select a book" ~options:available_books
                   >>= fun b -> (print_quotes qs b); Lwt_io.printf "" in
                 Lwt_main.run selected_book;
            )))

let () =
  Command.run ~version:"1.0" ~build_info:"test" command

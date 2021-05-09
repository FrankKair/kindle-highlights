open Core
open Lwt
open Kindle

let print_quotes qs =
  List.iter ~f:(printf "\n> %s\n") qs

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
               let l = Library.build (In_channel.read_lines filepath) in
               match book with
               | Some b -> (print_quotes (Library.quotes l b));
               | None ->
                 let selected_book =
                   Inquire.select "Select a book" ~options:(Library.books l)
                   >>= fun b ->
                   (print_quotes (Library.quotes l b));
                   Lwt_io.printf ""
                 in
                 Lwt_main.run selected_book;
            )))

let () =
  Command.run ~version:"0.0.1" ~build_info:"First version" command

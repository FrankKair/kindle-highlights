open Core
open Parser

let load_highlights filepath =
  In_channel.read_lines filepath

let print_books filepath =
  let qs = Quotes.build (load_highlights filepath) in
  List.iter ~f:(printf "%s\n") (Hashtbl.keys qs);

let prompt_for_book book =
  printf "%s\n" book;
  match In_channel.input_line In_channel.stdin with
  | None -> failwith "No value entered. Aborting."
  | Some book -> book

let command =
  Command.basic
    ~summary:"Reads My Clippings file and parses the highlights"
    ~readme:(fun () -> "More detailed info here")
    (Command.Param.(
       map (anon ("filepath" %: string))
       ~f:(fun filepath ->
         (fun () -> print_books filepath))))

let () = 
  Command.run ~version:"1.0" ~build_info:"test" command

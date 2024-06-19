open Core
open Kindle

let command =
  Command.basic
    ~summary:"Reads My Clippings file and parses the highlights"
    Command.Let_syntax.(
      let%map_open filepath = anon ("filepath" %: string) in
      fun () ->
        let lines = In_channel.read_lines filepath in
        let lib = Library.build_from(lines) in
        Inquire.select "Select a book" ~options:(Library.books lib)
        |> fun book ->
            List.iter ~f:(printf "\n> %s\n") (Library.quotes lib book);
    )

let () =
  Command_unix.run
    ~version:"0.0.1"
    ~build_info:"First version"
    command

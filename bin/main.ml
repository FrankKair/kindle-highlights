open Stdio
open Base
open Parser

let load_highlights =
  In_channel.read_lines "My\ Clippings.txt"

let () = 
  let qs = Quotes.build load_highlights in
  List.iter ~f:(printf "%s\n") (Hashtbl.keys qs);

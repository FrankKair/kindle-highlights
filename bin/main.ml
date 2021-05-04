open Stdio
open Base

let load_highlights =
  In_channel.read_lines "My\ Clippings.txt"

let () = 
  let quotes = Hashtbl.create (module String) in
  let lines = List.to_array load_highlights in
  let size = Array.length lines - 1 in
  let index = ref 0 in
  let loop = ref true in

  while !index < size && !loop do
    if !index > size - 6 then loop := false;

    let title = String.strip lines.(!index) in
    let contents = String.strip lines.(!index + 3) in

    Hashtbl.find_and_call quotes title
      ~if_found:(fun v -> Hashtbl.set quotes ~key:title ~data:(Array.append v [|contents|]))
      ~if_not_found:(fun _ -> Hashtbl.set quotes ~key:title ~data:[|contents|]);

    index := !index + 5;
  done;

  (*let qs = Hashtbl.find_exn quotes "Philosophy (Edward Craig)" in*)
  (*Array.iter ~f:(Stdio.printf "%s\n\n") qs;*)
  let keys = Hashtbl.keys quotes in
  List.iter ~f:(Stdio.printf "%s\n") keys;

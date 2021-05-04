open Base

let build input_lines = 
  let quotes = Hashtbl.create (module String) in
  let lines = List.to_array input_lines in
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
  quotes

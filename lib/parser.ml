open Base

let build_lib ~from:input_lines =
  let quotes = Hashtbl.create (module String) in
  let lines = List.to_array input_lines in
  let size = Array.length lines - 1 in
  let index = ref 0 in
  let loop = ref true in

  while !index < size && !loop do
    if !index > size - 6 then loop := false;
    let title =
      let title = ref (String.strip lines.(!index)) in
      if String.is_substring ~substring:"\u{feff}" !title then
        title := String.substr_replace_first
            ~pattern:"\u{feff}"
            ~with_:"" !title;
      !title
    in
    let contents = String.strip lines.(!index + 3) in

    Hashtbl.find_and_call quotes title
      ~if_found:(
        fun v -> Hashtbl.set quotes ~key:title ~data:(List.append v [contents])
      )
      ~if_not_found:(
        fun _ -> Hashtbl.set quotes ~key:title ~data:[contents]
      );

    index := !index + 5;
  done;
  quotes

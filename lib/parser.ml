open Base

let separator = "=========="
let strip_bom s = String.substr_replace_first ~pattern:"\u{feff}" ~with_:"" s

let split_blocks lines =
  let finish_block current acc =
    if List.is_empty current then acc else List.rev current :: acc
  in
  let rec loop remaining current acc =
    match remaining with
    | [] -> List.rev (finish_block current acc)
    | line :: tail ->
        if String.( = ) (String.strip line) separator then
          loop tail [] (finish_block current acc)
        else loop tail (line :: current) acc
  in
  loop lines [] []

let parse_block block =
  match block with
  | title :: metadata :: body ->
      if not (String.is_substring metadata ~substring:"Your Highlight") then
        None
      else
        let content =
          body
          |> List.drop_while ~f:(fun line ->
              String.is_empty (String.strip line))
          |> String.concat ~sep:"\n" |> String.strip
        in
        if String.is_empty content then None
        else Some (String.strip title, content)
  | _ -> None

let stable_dedup_strings xs =
  List.fold xs
    ~init:(Set.empty (module String), [])
    ~f:(fun (seen, acc) x ->
      if Set.mem seen x then (seen, acc) else (Set.add seen x, x :: acc))
  |> snd |> List.rev

(* Strip the UTF-8 BOM if present. Kindle writes \xEF\xBB\xBF at the start
   of My Clippings.txt. We handle it once here, at the file level, so
   individual block parsers don't need to worry about it. *)
let build_lib ~from:input_lines =
  let input_lines =
    match input_lines with first :: rest -> strip_bom first :: rest | [] -> []
  in
  input_lines |> split_blocks
  |> List.filter_map ~f:parse_block
  |> Map.of_alist_multi (module String)
  |> Map.map ~f:stable_dedup_strings

open Base

type entry = { title : string; contents : string }

let separator = "=========="

(* Strip the UTF-8 BOM if present. Kindle writes \xEF\xBB\xBF at the start
   of My Clippings.txt. We handle it once here, at the file level, so
   individual block parsers don't need to worry about it. *)
let strip_leading_bom line =
  let prefix = "\u{feff}" in
  if String.is_prefix line ~prefix then
    String.drop_prefix line (String.length prefix)
  else line

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

let parse_entry block =
  match block with
  | title :: metadata :: body ->
      let title = String.strip title in
      if
        String.is_empty title
        || not (String.is_substring metadata ~substring:"Your Highlight")
      then None
      else
        let contents =
          body
          |> List.drop_while ~f:(fun line ->
              String.is_empty (String.strip line))
          |> String.concat ~sep:"\n" |> String.strip
        in
        if String.is_empty contents then None else Some { title; contents }
  | _ -> None

(* Keep the tuple-shaped API for compatibility with existing callers.
   parse_lines exposes the richer entry representation. *)
let parse_block block =
  Option.map (parse_entry block) ~f:(fun { title; contents } ->
      (title, contents))

let parse_lines input_lines =
  let input_lines =
    match input_lines with
    | first :: rest -> strip_leading_bom first :: rest
    | [] -> []
  in
  input_lines |> split_blocks |> List.filter_map ~f:parse_entry

let stable_dedup_strings xs =
  List.fold xs
    ~init:(Set.empty (module String), [])
    ~f:(fun (seen, acc) x ->
      if Set.mem seen x then (seen, acc) else (Set.add seen x, x :: acc))
  |> snd |> List.rev

let build_lib ~from:input_lines =
  parse_lines input_lines
  |> List.map ~f:(fun { title; contents } -> (title, contents))
  |> Map.of_alist_multi (module String)
  |> Map.map ~f:stable_dedup_strings

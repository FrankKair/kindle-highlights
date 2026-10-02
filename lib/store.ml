type error =
  | Missing_home_directory
  | Missing_file
  | Invalid_data
  | Unsupported_version of int
  | Io_error of string

module Disk = struct
  open Base

  type entry = { title : string; contents : string } [@@deriving sexp]
  type entries = entry list [@@deriving sexp]
end

let format_name = "kindle-highlights"
let format_version = 1

let default_path () =
  let data_home =
    match Sys.getenv_opt "XDG_DATA_HOME" with
    | Some path when path <> "" && not (Filename.is_relative path) -> Ok path
    | _ -> (
        match Sys.getenv_opt "HOME" with
        | Some home when home <> "" -> Ok (Filename.concat home ".local/share")
        | _ -> Error Missing_home_directory)
  in
  match data_home with
  | Error _ as error -> error
  | Ok directory ->
      Ok (Filename.concat directory "kindle-highlights/library.sexp")

let to_disk (entry : Parser.entry) : Disk.entry =
  { title = entry.title; contents = entry.contents }

let from_disk (entry : Disk.entry) : Parser.entry =
  { title = entry.title; contents = entry.contents }

let valid_entry (entry : Disk.entry) =
  entry.title <> "" && entry.contents <> ""
  && entry.title = Base.String.strip entry.title
  && entry.contents = Base.String.strip entry.contents

let encode entries =
  Core.Sexp.List
    [
      Core.Sexp.Atom format_name;
      Core.Sexp.Atom (string_of_int format_version);
      Disk.sexp_of_entries (List.map to_disk entries);
    ]
  |> Core.Sexp.to_string_hum

let decode contents =
  let sexp = Core.Sexp.of_string contents in
  match sexp with
  | Core.Sexp.List [ Core.Sexp.Atom name; Core.Sexp.Atom version; entries ]
    when name = format_name -> (
      match int_of_string_opt version with
      | Some version when version <> format_version ->
          Error (Unsupported_version version)
      | Some _ ->
          let entries = Disk.entries_of_sexp entries in
          if List.for_all valid_entry entries then
            Ok (List.map from_disk entries)
          else Error Invalid_data
      | None -> Error Invalid_data)
  | _ -> Error Invalid_data

let rec ensure_directory path =
  if not (Sys.file_exists path) then (
    let parent = Filename.dirname path in
    if parent <> path then ensure_directory parent;
    try Unix.mkdir path 0o700 with Unix.Unix_error (Unix.EEXIST, _, _) -> ())

let save ~path entries =
  if not (List.for_all valid_entry (List.map to_disk entries)) then
    Error Invalid_data
  else
    try
      let directory = Filename.dirname path in
      ensure_directory directory;
      let temporary =
        Filename.temp_file ~temp_dir:directory ".kindle-highlights-" ".tmp"
      in
      Fun.protect
        ~finally:(fun () ->
          if Sys.file_exists temporary then Sys.remove temporary)
        (fun () ->
          Unix.chmod temporary 0o600;
          let channel = open_out_bin temporary in
          (try
             output_string channel (encode entries);
             close_out channel
           with exn ->
             close_out_noerr channel;
             raise exn);
          Unix.rename temporary path);
      Ok ()
    with
    | Sys_error message -> Error (Io_error message)
    | Unix.Unix_error (code, function_name, _) ->
        Error (Io_error (function_name ^ ": " ^ Unix.error_message code))

let load ~path =
  if not (Sys.file_exists path) then Error Missing_file
  else
    try
      let channel = open_in_bin path in
      let contents =
        Fun.protect
          ~finally:(fun () -> close_in_noerr channel)
          (fun () -> really_input_string channel (in_channel_length channel))
      in
      try decode contents with _ -> Error Invalid_data
    with
    | Sys_error message -> Error (Io_error message)
    | Unix.Unix_error (code, function_name, _) ->
        Error (Io_error (function_name ^ ": " ^ Unix.error_message code))

let error_to_string = function
  | Missing_home_directory -> "HOME is not set"
  | Missing_file -> "no saved highlights found"
  | Invalid_data -> "saved highlights are malformed"
  | Unsupported_version version ->
      Printf.sprintf "unsupported saved highlights version: %d" version
  | Io_error message -> message

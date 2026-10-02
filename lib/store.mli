type error =
  | Missing_home_directory
  | Missing_file
  | Invalid_data
  | Unsupported_version of int
  | Io_error of string

val default_path : unit -> (string, error) Result.t
(** Resolve the library path using [XDG_DATA_HOME], or [$HOME/.local/share] when
    it is unset. *)

val save : path:string -> Parser.entry list -> (unit, error) Result.t
(** Replace the saved entries. The previous file remains intact if writing fails
    before the final rename. *)

val load : path:string -> (Parser.entry list, error) Result.t
(** Read saved entries. A missing file is reported separately from malformed
    data or an unsupported format version. *)

val error_to_string : error -> string

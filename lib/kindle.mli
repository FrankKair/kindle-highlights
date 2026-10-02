open Base

module Parser : sig
  type entry = { title : string; contents : string }

  val parse_block : string list -> (string * string) option
  val parse_lines : string list -> entry list
  val index_entries : entry list -> string list Map.M(String).t
  val build_lib : from:string list -> string list Map.M(String).t
end

module Store : sig
  type error =
    | Missing_home_directory
    | Missing_file
    | Invalid_data
    | Unsupported_version of int
    | Io_error of string

  val default_path : unit -> (string, error) Result.t
  val save : path:string -> Parser.entry list -> (unit, error) Result.t
  val load : path:string -> (Parser.entry list, error) Result.t
  val error_to_string : error -> string
end

module Bookshelf : sig
  type t

  val of_entries : Parser.entry list -> t
  val build_from : string list -> t
  val books : t -> string list
  val quotes : t -> string -> string list option
end

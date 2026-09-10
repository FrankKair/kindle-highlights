open Base

module Parser : sig
  val parse_block : string list -> (string * string) option
  val build_lib : from:string list -> string list Map.M(String).t
end

module Bookshelf : sig
  type t

  val build_from : string list -> t
  val books : t -> string list
  val quotes : t -> string -> string list option
end

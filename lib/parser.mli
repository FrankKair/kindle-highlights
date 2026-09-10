open Base

val parse_block : string list -> (string * string) option
val build_lib : from:string list -> string list Map.M(String).t

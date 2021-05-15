open Base

module Library : sig
  type ('a, 'b) t
  val build : string list -> ('a, 'b) t
  val books : ('a, 'b) t -> string list
  val quotes : ('a, 'b) t -> string -> string list
end = struct
  type ('a, 'b) t = (string, string list) Hashtbl.t
  let build lines = Parser.build_lib ~from:lines
  let books ht = Hashtbl.keys ht
  let quotes ht book = Hashtbl.find_exn ht book
end

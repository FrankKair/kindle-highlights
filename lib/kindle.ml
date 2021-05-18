open Base

module Library = struct
  type ('a, 'b) t = (string, string list) Hashtbl.t
  let build lines = Parser.build_lib ~from:lines
  let books ht = Hashtbl.keys ht
  let quotes ht book = Hashtbl.find_exn ht book
end

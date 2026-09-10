open Base
module Parser = Parser

module Bookshelf = struct
  type t = string list Map.M(String).t

  let build_from lines = Parser.build_lib ~from:lines
  let books t = Map.keys t
  let quotes t book = Map.find t book
end

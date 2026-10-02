open Base
module Parser = Parser
module Store = Store

module Bookshelf = struct
  type t = string list Map.M(String).t

  let of_entries entries = Parser.index_entries entries
  let build_from lines = Parser.parse_lines lines |> of_entries
  let books t = Map.keys t
  let quotes t book = Map.find t book
end

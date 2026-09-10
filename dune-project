(lang dune 3.0)
(name kindle_highlights)

(generate_opam_files true)

(source (github FrankKair/kindle-highlights))

(license MIT)

(authors "Frank Kair")
(maintainers "Frank Kair <frankkair@gmail.com>")
(homepage https://github.com/FrankKair/kindle-highlights)
(bug_reports https://github.com/FrankKair/kindle-highlights/issues)

(package
 (name kindle_highlights)
 (synopsis "An OCaml program to browse Kindle highlights")
 (description "Parse Kindle clippings and browse highlights in the terminal")
 (depends
  (ocaml (>= 5.0))
  (dune (>= 3.0))
  (stdio (>= v0.14.0))
  (core (>= v0.14.1))
  (core_unix (>= v0.14.0))
  (ppx_jane (>= v0.17.0))
  (alcotest :with-test)))

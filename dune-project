(lang dune 2.8)
(name kindle_highlights)

(generate_opam_files true)

(package
 (name kindle_highlights)
 (synopsis "An OCaml program see your Kindle highlights")
 (description "A longer description")
 (depends
  (dune (>= 2.8))
  (stdio (>= v0.14.0))
  (core (>= v0.14.1))
  (inquire (>= v0.2.1))
  (lwt (>= 5.4.1))))

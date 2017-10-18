#if OCAML_VERSION < (4, 03, 0)
  let capitalize_ascii = String.capitalize
#else
  let capitalize_ascii = String.capitalize_ascii
#endif

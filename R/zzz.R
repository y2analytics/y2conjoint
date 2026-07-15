.onLoad <- function(libname, pkgname) {
  S7::methods_register()
  # methods_register() drops plain S3 methods on the print generic, so restore
  # the collected_df/conjoint_df print methods afterwards.
  registerS3method(
    "print",
    "collected_df",
    print_collected_df,
    envir = asNamespace(pkgname)
  )
  registerS3method(
    "print",
    "conjoint_df",
    print_conjoint_df,
    envir = asNamespace(pkgname)
  )
}

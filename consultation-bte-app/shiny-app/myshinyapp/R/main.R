#' Run the Shiny Application
#'
#' @description Launch the Consultation BTE Shiny application
#'
#' @param ... Additional arguments to pass to shiny::runApp()
#'
#' @export
#' @importFrom shiny runApp
#'
#' @examples
#' \dontrun{
#' run_app()
#' }
run_app <- function(...) {
  app_dir <- system.file("app", package = "myshinyapp")
  
  if (app_dir == "") {
    stop("Could not find application directory. Try re-installing `myshinyapp`.", call. = FALSE)
  }
  
  shiny::runApp(app_dir, ...)
}

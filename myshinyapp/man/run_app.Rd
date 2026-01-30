\name{run_app}
\alias{run_app}
\title{Run the Consultation BTE Shiny Application}
\usage{
run_app(...)
}
\arguments{
\item{...}{Additional arguments to pass to \code{shiny::runApp()}}
}
\description{
Launches the Consultation BTE Shiny application for civic consultation.
}
\examples{
\dontrun{
# Run the application
run_app()

# Run with specific port
run_app(port = 8080)

# Run with specific host
run_app(host = "0.0.0.0", port = 3838)
}
}
\author{
Your Name
}

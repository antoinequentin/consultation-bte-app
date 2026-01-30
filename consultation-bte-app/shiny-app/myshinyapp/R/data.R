#' Questions List for BTE Consultation
#'
#' @description List of questions organized by category for the consultation
#' @format A list with question categories
questions_list <- list(
  general = list(
    list(
      id = "q1",
      categorie = "ADAPTATION",
      texte = "Comment le projet contribue-t-il à s'adapter au climat actuel et futur ?"
    ),
    list(
      id = "q2",
      categorie = "ATTÉNUATION",
      texte = "Comment le projet contribue-t-il à réduire les émissions de gaz à effet de serre ?"
    ),
    list(
      id = "q3",
      categorie = "RESSOURCE EN EAU",
      texte = "Comment le projet contribue-t-il à la gestion durable des ressources en eau ?"
    ),
    list(
      id = "q4",
      categorie = "BIODIVERSITÉ",
      texte = "Comment le projet contribue-t-il à la protection et à la restauration de la biodiversité et des écosystèmes ?"
    ),
    list(
      id = "q5",
      categorie = "POLLUTION",
      texte = "Comment le projet contribue-t-il à la prévention et à la réduction des pollutions ?"
    ),
    list(
      id = "q6",
      categorie = "ÉCONOMIE CIRCULAIRE",
      texte = "Comment le projet contribue-t-il à la transition vers une économie circulaire, à la prévention des déchets ou au recyclage ?"
    )
  )
)

#' Get All Questions
#'
#' @description Retrieve all questions in order
#' @return List of all questions
#' @export
get_all_questions <- function() {
  all_q <- c(questions_list$general)
  return(all_q)
}

#' Get Category Color
#'
#' @param categorie Category name
#' @return Hex color code
#' @export
get_category_color <- function(categorie) {
  colors <- list(
    "ADAPTATION" = "#ff9a00",
    "ATTÉNUATION" = "#669a9a",
    "RESSOURCE EN EAU" = "#0066cd",
    "BIODIVERSITÉ" = "#009a00",
    "POLLUTION" = "#9a6600",
    "ÉCONOMIE CIRCULAIRE" = "#009a66"
  )
  colors[[categorie]] %||% "#000091"
}

#' Get Step Name
#'
#' @param step Step number (0-4)
#' @return Step name with emoji
#' @export
get_step_name <- function(step) {
  steps <- c("Aucune", "👍 Impacts positifs", "👎 Impacts négatifs", "🗳️ Vote", "🔄 Améliorations")
  steps[step + 1]
}

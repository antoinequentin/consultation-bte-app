# ============================================================================
# SERVER - CONSULTATION BTE
# ============================================================================

library(shiny)
library(dplyr)
library(plotly)

# ============================================================================
# CONFIGURATION
# ============================================================================

ADMIN_PASSWORD <- Sys.getenv("ADMIN_PASSWORD", "admin2026")
PROJECT_NAME <- "Webinaire Atelier Boussole de la Transition Écologique"
PROJECT_DESCRIPTION <- "Amélioration collaborative d'un projet"

# Paramètres de rafraîchissement
REFRESH_INTERVAL_MS <- 1000
FILE_READER_INTERVAL_MS <- 300

# ============================================================================
# INITIALISATION
# ============================================================================

initialize_data <- function() {
  if (!dir.exists("data")) dir.create("data", recursive = TRUE)
  if (!dir.exists("www")) dir.create("www", recursive = TRUE)
  
  if (!file.exists("data/responses.rds")) {
    responses_df <- data.frame(
      timestamp = character(),
      participant_id = character(),
      question_id = character(),
      categorie = character(),
      reponse = character(),
      stringsAsFactors = FALSE
    )
    saveRDS(responses_df, "data/responses.rds")
  }
  
  if (!file.exists("data/active_question.rds")) {
    saveRDS(
      list(question_id = NULL, question_num = 0, step = 0),
      "data/active_question.rds"
    )
  }
  
  # Initialiser les propositions
  if (!file.exists("data/propositions.rds")) {
    propositions_df <- data.frame(
      id = character(),
      question_id = character(),
      type = character(),
      participant_id = character(),
      texte = character(),
      timestamp = character(),
      accord = integer(),
      desaccord = integer(),
      passer = integer(),
      stringsAsFactors = FALSE
    )
    saveRDS(propositions_df, "data/propositions.rds")
  }
  
  if (!file.exists("data/votes.rds")) {
    votes_df <- data.frame(
      participant_id = character(),
      proposition_id = character(),
      vote = character(),
      timestamp = character(),
      stringsAsFactors = FALSE
    )
    saveRDS(votes_df, "data/votes.rds")
  }
}

initialize_data()
all_questions <- myshinyapp::get_all_questions()

# ============================================================================
# UI HELPER FUNCTIONS
# ============================================================================

#' Créer l'UI pour afficher et voter sur les propositions
render_propositions_ui <- function(propositions, participant_id, type_consultation, question_id) {
  if (nrow(propositions) == 0) {
    return(
      tags$div(
        class = "no-statements",
        tags$p("Aucune proposition pour le moment. Soyez le premier à contribuer !")
      )
    )
  }
  
  proposition_items <- lapply(1:nrow(propositions), function(i) {
    prop <- propositions[i, ]
    user_vote <- myshinyapp::get_user_vote(participant_id, prop$id)
    consensus <- myshinyapp::calculate_consensus_score(prop$accord, prop$desaccord, prop$passer)
    
    tags$div(
      class = "statement-item",
      id = paste0("statement_", prop$id),
      `data-prop-id` = prop$id,
      
      tags$div(
        class = "statement-text",
        prop$texte
      ),
      
      tags$div(
        class = "statement-votes",
        tags$div(
          class = "vote-buttons",
          style = "display: flex; gap: 10px; margin-bottom: 15px;",
          
          # Bouton D'accord
          tags$button(
            class = paste("vote-btn vote-btn-agree", if (!is.null(user_vote) && user_vote == "accord") "active" else ""),
            `data-prop-id` = prop$id,
            `data-vote-type` = "accord",
            onclick = sprintf("Shiny.setInputValue('vote_action', {prop_id: '%s', vote: 'accord', timestamp: Date.now()}, {priority: 'event'});", prop$id),
            tags$span("✓"),
            " D'accord"
          ),
          
          # Bouton Pas d'accord
          tags$button(
            class = paste("vote-btn vote-btn-disagree", if (!is.null(user_vote) && user_vote == "desaccord") "active" else ""),
            `data-prop-id` = prop$id,
            `data-vote-type` = "desaccord",
            onclick = sprintf("Shiny.setInputValue('vote_action', {prop_id: '%s', vote: 'desaccord', timestamp: Date.now()}, {priority: 'event'});", prop$id),
            tags$span("✕"),
            " Pas d'accord"
          ),
          
          # Bouton Passer
          tags$button(
            class = paste("vote-btn vote-btn-pass", if (!is.null(user_vote) && user_vote == "passer") "active" else ""),
            `data-prop-id` = prop$id,
            `data-vote-type` = "passer",
            onclick = sprintf("Shiny.setInputValue('vote_action', {prop_id: '%s', vote: 'passer', timestamp: Date.now()}, {priority: 'event'});", prop$id),
            tags$span("−"),
            " Passer"
          )
        ),
        
        # Statistiques de votes
        tags$div(
          class = "vote-stats",
          id = paste0("vote_stats_", prop$id),
          tags$div(
            class = "vote-stat-item",
            tags$span(style = "color: #00A95F;", "✓"),
            tags$span(id = paste0("accord_count_", prop$id), prop$accord)
          ),
          tags$div(
            class = "vote-stat-item",
            tags$span(style = "color: #E1000F;", "✕"),
            tags$span(id = paste0("desaccord_count_", prop$id), prop$desaccord)
          ),
          tags$div(
            class = "vote-stat-item",
            tags$span(style = "color: #666;", "−"),
            tags$span(id = paste0("passer_count_", prop$id), prop$passer)
          ),
          tags$div(
            class = "vote-stat-item consensus-score",
            tags$span(
              id = paste0("consensus_", prop$id),
              style = "font-weight: bold; color: #000091;",
              paste0(consensus, "% accord")
            )
          )
        )
      )
    )
  })
  
  tags$div(
    class = "statements-list",
    id = paste0("statements_list_", type_consultation),
    proposition_items
  )
}

#' Créer le formulaire pour ajouter une nouvelle proposition
render_new_proposition_form <- function(type_consultation, question_id) {
  title_map <- list(
    "positifs" = "Proposer un impact positif",
    "negatifs" = "Proposer un impact négatif",
    "ameliorations" = "Proposer une amélioration"
  )
  
  placeholder_map <- list(
    "positifs" = "Décrivez un impact positif du projet...",
    "negatifs" = "Décrivez un impact négatif du projet...",
    "ameliorations" = "Proposez une amélioration au projet..."
  )
  
  tags$div(
    class = "new-statement-form",
    tags$h4(title_map[[type_consultation]], style = "color: #000091; margin-top: 0;"),
    textAreaInput(
      inputId = paste0("new_prop_", type_consultation),
      label = NULL,
      placeholder = placeholder_map[[type_consultation]],
      width = "100%",
      rows = 3
    ),
    tags$div(
      style = "text-align: right; font-size: 0.9rem; color: #666; margin-bottom: 10px;",
      textOutput(paste0("char_count_", type_consultation), inline = TRUE)
    ),
    actionButton(
      inputId = paste0("submit_prop_", type_consultation),
      label = "📤 Soumettre ma proposition",
      class = "fr-btn",
      style = "width: 100%;"
    )
  )
}

# ============================================================================
# SERVER FUNCTION
# ============================================================================

server <- function(input, output, session) {
  
  # ID unique du participant
  participant_id <- reactive({
    if (is.null(session$user)) {
      paste0("user_", substr(session$token, 1, 8))
    } else {
      paste0("user_", session$user)
    }
  })
  
  # Cache pour les propositions
  polis_cache <- reactiveValues(
    positifs = NULL,
    negatifs = NULL,
    ameliorations = NULL,
    last_update = Sys.time()
  )
  
  # Déclencheur pour forcer le rafraîchissement des propositions
  polis_refresh_trigger <- reactiveVal(0)
  
  # État d'authentification admin
  admin_logged_in <- reactiveVal(FALSE)
  
  # ========================================================================
  # CHARGEMENT DES DONNÉES
  # ========================================================================
  
  load_responses <- reactive({
    invalidateLater(REFRESH_INTERVAL_MS, session)
    if (file.exists("data/responses.rds")) {
      readRDS("data/responses.rds")
    } else {
      data.frame(
        timestamp = character(),
        participant_id = character(),
        question_id = character(),
        categorie = character(),
        reponse = character(),
        stringsAsFactors = FALSE
      )
    }
  })
  
  load_active_question <- reactiveFileReader(
    intervalMillis = REFRESH_INTERVAL_MS,
    session = session,
    filePath = "data/active_question.rds",
    readFunc = function(filePath) {
      if (file.exists(filePath)) {
        readRDS(filePath)
      } else {
        list(question_id = NULL, question_num = 0, step = 0)
      }
    }
  )
  
  load_propositions_cached <- reactiveFileReader(
    intervalMillis = FILE_READER_INTERVAL_MS,
    session = session,
    filePath = "data/propositions.rds",
    readFunc = function(filePath) {
      if (file.exists(filePath)) {
        readRDS(filePath)
      } else {
        data.frame(
          id = character(),
          question_id = character(),
          type = character(),
          participant_id = character(),
          texte = character(),
          timestamp = character(),
          accord = integer(),
          desaccord = integer(),
          passer = integer(),
          stringsAsFactors = FALSE
        )
      }
    }
  )
  
  # Observer pour synchroniser le trigger avec les changements de fichiers
  observe({
    load_propositions_cached()
    isolate(polis_refresh_trigger(polis_refresh_trigger() + 1))
  })
  
  load_votes_cached <- reactiveFileReader(
    intervalMillis = FILE_READER_INTERVAL_MS,
    session = session,
    filePath = "data/votes.rds",
    readFunc = function(filePath) {
      if (file.exists(filePath)) {
        readRDS(filePath)
      } else {
        data.frame(
          participant_id = character(),
          proposition_id = character(),
          vote = character(),
          timestamp = character(),
          stringsAsFactors = FALSE
        )
      }
    }
  )
  
  save_active_question <- function(question_id, question_num, step) {
    saveRDS(
      list(question_id = question_id, question_num = question_num, step = step),
      "data/active_question.rds"
    )
  }
  
  get_active_question <- reactive({
    active <- load_active_question()
    if (is.null(active$question_id) || active$question_num == 0) return(NULL)
    if (active$question_num > length(all_questions)) return(NULL)
    all_questions[[active$question_num]]
  })
  
  has_participant_answered <- reactive({
    responses <- load_responses()
    active <- load_active_question()
    if (is.null(active$question_id)) return(FALSE)
    any(responses$participant_id == participant_id() & 
          responses$question_id == active$question_id)
  })
  
  # ========================================================================
  # AUTHENTIFICATION ADMINISTRATEUR
  # ========================================================================
  
  output$admin_authenticated <- reactive({ admin_logged_in() })
  outputOptions(output, "admin_authenticated", suspendWhenHidden = FALSE)
  
  observeEvent(input$admin_login, {
    if (input$admin_password == ADMIN_PASSWORD) {
      admin_logged_in(TRUE)
    } else {
      showNotification("Mot de passe incorrect", type = "error")
    }
  })
  
  observeEvent(input$admin_logout, { 
    admin_logged_in(FALSE) 
  })
  
  output$login_error <- renderUI({
    if (input$admin_login > 0 && !admin_logged_in()) {
      tags$div(
        style = "color: #E1000F; margin-top: 15px; font-weight: 500;",
        "❌ Mot de passe incorrect"
      )
    }
  })
  
  # ========================================================================
  # CONDITIONS D'AFFICHAGE PARTICIPANT
  # ========================================================================
  
  output$participant_waiting <- reactive({
    active <- load_active_question()
    is.null(active$question_id) || active$question_num == 0
  })
  outputOptions(output, "participant_waiting", suspendWhenHidden = FALSE)
  
  output$participant_has_question <- reactive({
    active <- load_active_question()
    !is.null(active$question_id) && 
      active$question_num > 0 && 
      active$question_num <= length(all_questions)
  })
  outputOptions(output, "participant_has_question", suspendWhenHidden = FALSE)
  
  output$participant_finished <- reactive({
    active <- load_active_question()
    !is.null(active$question_num) && active$question_num > length(all_questions)
  })
  outputOptions(output, "participant_finished", suspendWhenHidden = FALSE)
  
  output$participant_answered <- reactive({ 
    has_participant_answered() 
  })
  outputOptions(output, "participant_answered", suspendWhenHidden = FALSE)
  
  # Affichage des étapes
  output$show_step_positifs <- reactive({
    active <- load_active_question()
    !is.null(active$step) && active$step == 1
  })
  outputOptions(output, "show_step_positifs", suspendWhenHidden = FALSE)
  
  output$show_step_negatifs <- reactive({
    active <- load_active_question()
    !is.null(active$step) && active$step == 2
  })
  outputOptions(output, "show_step_negatifs", suspendWhenHidden = FALSE)
  
  output$show_step_vote <- reactive({
    active <- load_active_question()
    !is.null(active$step) && active$step == 3
  })
  outputOptions(output, "show_step_vote", suspendWhenHidden = FALSE)
  
  output$show_step_ameliorations <- reactive({
    active <- load_active_question()
    !is.null(active$step) && active$step == 4
  })
  outputOptions(output, "show_step_ameliorations", suspendWhenHidden = FALSE)
  
  # ========================================================================
  # PARTICIPANT UI MODULES
  # ========================================================================
  
  # Barre de progression
  output$progress_style <- renderText({
    active <- load_active_question()
    if (is.null(active$question_num)) return("width: 0%;")
    progress <- (active$question_num / length(all_questions)) * 100
    paste0("width: ", round(progress), "%;")
  })
  
  output$progress_text <- renderText({
    active <- load_active_question()
    if (is.null(active$question_num)) return("")
    paste0("Question ", active$question_num, " / ", length(all_questions))
  })
  
  # Indicateur d'étapes
  output$step_indicator <- renderUI({
    active <- load_active_question()
    if (is.null(active$step)) return(NULL)
    
    current_step <- active$step
    
    tags$div(
      class = "step-indicator",
      
      tags$div(
        class = if (current_step == 1) "step-item active" else if (current_step > 1) "step-item completed" else "step-item",
        tags$div(class = "step-number", "1"),
        tags$div(class = "step-label", "Impacts positifs")
      ),
      
      tags$div(
        class = if (current_step == 2) "step-item active" else if (current_step > 2) "step-item completed" else "step-item",
        tags$div(class = "step-number", "2"),
        tags$div(class = "step-label", "Impacts négatifs")
      ),
      
      tags$div(
        class = if (current_step == 3) "step-item active" else if (current_step > 3) "step-item completed" else "step-item",
        tags$div(class = "step-number", "3"),
        tags$div(class = "step-label", "Vote")
      ),
      
      tags$div(
        class = if (current_step == 4) "step-item active" else "step-item",
        tags$div(class = "step-number", "4"),
        tags$div(class = "step-label", "Améliorations")
      )
    )
  })
  
  # Description du projet
  output$project_description <- renderUI({
    tags$div(
      style = "padding: 25px; background: #f6f6f6; text-align: left;",
      tags$h4(PROJECT_NAME, style = "color: #000091; margin: 0 0 20px 0; font-size: 1.5rem;"),
      
      tags$h5("État des lieux : Le bâtiment existant (héritage des années 70 et 80)", 
        style = "color: #000091; margin-top: 20px; margin-bottom: 12px; font-size: 1.2rem;"),
      tags$p("Le site actuel est occupé par un complexe administratif typique de l'architecture fonctionnaliste et minérale de la fin du XXe siècle :", 
        style = "margin-bottom: 12px; font-size: 1.05rem; line-height: 1.6;"),
      tags$ul(
        style = "margin-left: 20px; font-size: 1rem; line-height: 1.7;",
        tags$li(tags$strong("Structure : "), "Un monolithe de béton brut, imposant et rigide, dont l'inertie thermique est mal maîtrisée."),
        tags$li(tags$strong("Performance énergétique : "), "Malgré la présence de doubles vitrages sur cadres en aluminium, le bâtiment reste une \"passoire thermique\" en raison de nombreux ponts thermiques."),
        tags$li(tags$strong("L'espace intérieur : "), "Très cloisonné, impose un recours systématique à l'éclairage artificiel, même en plein jour en été."),
        tags$li(tags$strong("Insertion urbaine : "), "Un bâtiment déconnecté de son environnement, malgré sa proximité avec un parc arboré.")
      ),
      
      tags$h5("Le Projet : Réhabilitation thermique et transition énergétique", 
        style = "color: #000091; margin-top: 20px; margin-bottom: 12px; font-size: 1.2rem;"),
      tags$p("Le programme vise une mise aux nouvelles normes :", 
        style = "margin-bottom: 12px; font-size: 1.05rem; line-height: 1.6;"),
      tags$ul(
        style = "margin-left: 20px; font-size: 1rem; line-height: 1.7;",
        tags$li(tags$strong("Enveloppe thermique : "), "Mise en œuvre d'une isolation thermique par l'extérieur pour supprimer les ponts thermiques et redonner une esthétique contemporaine à la façade."),
        tags$li(tags$strong("Système de chauffage : "), "Remplacement de l'ancienne chaudière au fioul par une chaudière gaz à condensation haute performance."),
        tags$li(tags$strong(" Extension sur le parc : "), "Création d'un nouveau volume en structure bois, vitré (entrainant la coupe d'arbre)")
      )
    )
  })
  
  # Badge catégorie
  output$question_badge <- renderUI({
    question <- get_active_question()
    if (is.null(question)) return(NULL)
    
    color <- myshinyapp::get_category_color(question$categorie)
    
    tags$div(
      class = "categorie-badge",
      style = paste0("background: ", color, "; color: white;"),
      question$categorie
    )
  })
  
  # Affichage de la question
  output$question_display <- renderUI({
    question <- get_active_question()
    if (is.null(question)) return(NULL)
    
    color <- myshinyapp::get_category_color(question$categorie)
    
    tags$div(
      class = "question-highlight",
      style = paste0(
        "font-size: 1.8rem; font-weight: 700; line-height: 1.6; margin-bottom: 40px; ",
        "padding: 30px; background: linear-gradient(135deg, #f8f9ff 0%, #ffffff 100%); ",
        "border-radius: 12px; border-left: 6px solid ", color, "; ",
        "box-shadow: 0 4px 15px rgba(0,0,0,0.1);"
      ),
      question$texte
    )
  })
  
  # ========================================================================
  # ÉTAPES - IMPACTS POSITIFS
  # ========================================================================
  
  output$step_positifs_content <- renderUI({
    question <- get_active_question()
    if (is.null(question)) return(NULL)
    
    propositions <- load_propositions_cached()
    propositions_positifs <- propositions %>%
      filter(question_id == question$id, type == "positifs") %>%
      arrange(desc(accord))
    
    tagList(
      tags$h3("👍 Impacts positifs du projet", style = "color: #00A95F; margin-bottom: 20px;"),
      tags$p("Consultez les impacts positifs proposés par les participants et votez pour ceux avec lesquels vous êtes d'accord.", 
        style = "margin-bottom: 25px; color: #666;"),
      uiOutput("propositions_positifs_list", container = tags$div),
      render_new_proposition_form("positifs", question$id)
    )
  })
  
  output$propositions_positifs_list <- renderUI({
    question <- get_active_question()
    if (is.null(question)) return(NULL)
    
    propositions <- load_propositions_cached()
    propositions_positifs <- propositions %>%
      filter(question_id == question$id, type == "positifs") %>%
      arrange(desc(accord))
    
    render_propositions_ui(propositions_positifs, participant_id(), "positifs", question$id)
  })
  
  output$char_count_positifs <- renderText({
    text <- input$new_prop_positifs
    if (is.null(text)) return("0 / 500 caractères")
    paste0(nchar(text), " / 500 caractères")
  })
  
  observeEvent(input$submit_prop_positifs, {
    question <- get_active_question()
    text <- input$new_prop_positifs
    
    if (is.null(text) || nchar(trimws(text)) < 10) {
      showNotification("Votre proposition doit contenir au moins 10 caractères.", type = "warning")
      return()
    }
    
    if (nchar(text) > 500) {
      showNotification("Votre proposition ne peut pas dépasser 500 caractères.", type = "warning")
      return()
    }
    
    prop_id <- myshinyapp::add_proposition(question$id, "positifs", participant_id(), trimws(text))
    updateTextAreaInput(session, "new_prop_positifs", value = "")
    showNotification("✓ Votre proposition a été ajoutée avec succès !", type = "message")
  })
  
  # ========================================================================
  # ÉTAPES - IMPACTS NÉGATIFS
  # ========================================================================
  
  output$step_negatifs_content <- renderUI({
    question <- get_active_question()
    if (is.null(question)) return(NULL)
    
    propositions <- load_propositions_cached()
    propositions_negatifs <- propositions %>%
      filter(question_id == question$id, type == "negatifs") %>%
      arrange(desc(accord))
    
    tagList(
      tags$h3("👎 Impacts négatifs du projet", style = "color: #E1000F; margin-bottom: 20px;"),
      tags$p("Consultez les impacts négatifs proposés par les participants et votez pour ceux avec lesquels vous êtes d'accord.", 
        style = "margin-bottom: 25px; color: #666;"),
      uiOutput("propositions_negatifs_list", container = tags$div),
      render_new_proposition_form("negatifs", question$id)
    )
  })
  
  output$propositions_negatifs_list <- renderUI({
    question <- get_active_question()
    if (is.null(question)) return(NULL)
    
    propositions <- load_propositions_cached()
    propositions_negatifs <- propositions %>%
      filter(question_id == question$id, type == "negatifs") %>%
      arrange(desc(accord))
    
    render_propositions_ui(propositions_negatifs, participant_id(), "negatifs", question$id)
  })
  
  output$char_count_negatifs <- renderText({
    text <- input$new_prop_negatifs
    if (is.null(text)) return("0 / 500 caractères")
    paste0(nchar(text), " / 500 caractères")
  })
  
  observeEvent(input$submit_prop_negatifs, {
    question <- get_active_question()
    text <- input$new_prop_negatifs
    
    if (is.null(text) || nchar(trimws(text)) < 10) {
      showNotification("Votre proposition doit contenir au moins 10 caractères.", type = "warning")
      return()
    }
    
    if (nchar(text) > 500) {
      showNotification("Votre proposition ne peut pas dépasser 500 caractères.", type = "warning")
      return()
    }
    
    prop_id <- myshinyapp::add_proposition(question$id, "negatifs", participant_id(), trimws(text))
    updateTextAreaInput(session, "new_prop_negatifs", value = "")
    showNotification("✓ Votre proposition a été ajoutée avec succès !", type = "message")
  })
  
  # ========================================================================
  # ÉTAPE - VOTE
  # ========================================================================
  
  output$step_vote_content <- renderUI({
    question <- get_active_question()
    if (is.null(question)) return(NULL)
    
    tagList(
      conditionalPanel(
        condition = "!output.participant_answered",
        tags$div(
          style = "text-align: left;",
          tags$h3("🗳️ Vote de la cotation du projet sur l'axe :", style = "color: #000091; margin-bottom: 25px;"),
          tags$div(
            class = "response-btn response-btn-favorable",
            onclick = "Shiny.setInputValue('participant_response', 'FAVORABLE', {priority: 'event'});",
            tags$div(class = "response-icon icon-favorable", "✓"),
            tags$div(style = "font-size: 1.2rem; font-weight: bold;", "FAVORABLE")
          ),
          tags$div(
            class = "response-btn response-btn-neutre",
            onclick = "Shiny.setInputValue('participant_response', 'NEUTRE', {priority: 'event'});",
            tags$div(class = "response-icon icon-neutre", "−"),
            tags$div(style = "font-size: 1.2rem; font-weight: bold;", "NEUTRE")
          ),
          tags$div(
            class = "response-btn response-btn-defavorable",
            onclick = "Shiny.setInputValue('participant_response', 'DÉFAVORABLE', {priority: 'event'});",
            tags$div(class = "response-icon icon-defavorable", "✕"),
            tags$div(style = "font-size: 1.2rem; font-weight: bold;", "DÉFAVORABLE")
          )
        )
      ),
      
      conditionalPanel(
        condition = "output.participant_answered",
        tags$div(
          class = "text-center",
          style = "padding: 40px; background: #f0fff4; border-radius: 10px; border: 2px solid #00A95F;",
          tags$div(style = "font-size: 60px; margin-bottom: 15px;", "✓"),
          tags$h3("Vote enregistré !", style = "color: #00A95F; margin: 0;"),
          tags$p("Merci pour votre participation.", style = "color: #666; margin-top: 10px;")
        )
      ),
      
      # Résultats en temps réel
      tags$div(
        style = "margin-top: 40px;",
        tags$h3("📊 Résultats en temps réel", style = "color: #000091; margin: 25px 0; font-size: 1.4rem;"),
        fluidRow(
          column(3, tags$div(class = "stats-card", style = "background: linear-gradient(135deg, #000091, #6A6AF4);",
            tags$span(class = "stat-number", textOutput("live_total")),
            tags$span(class = "stat-label", "Total"))),
          column(3, tags$div(class = "stats-card", style = "background: linear-gradient(135deg, #00A95F, #009081);",
            tags$span(class = "stat-number", textOutput("live_favorable")),
            tags$span(class = "stat-label", "✓ Favorable"))),
          column(3, tags$div(class = "stats-card", style = "background: linear-gradient(135deg, #666, #929292);",
            tags$span(class = "stat-number", textOutput("live_neutre")),
            tags$span(class = "stat-label", "− Neutre"))),
          column(3, tags$div(class = "stats-card", style = "background: linear-gradient(135deg, #E1000F, #CE614A);",
            tags$span(class = "stat-number", textOutput("live_defavorable")),
            tags$span(class = "stat-label", "✕ Défavorable")))
        )
      )
    )
  })
  
  observeEvent(input$participant_response, {
    question <- get_active_question()
    if (is.null(question)) return()
    
    responses <- load_responses()
    
    new_response <- data.frame(
      timestamp = as.character(Sys.time()),
      participant_id = participant_id(),
      question_id = question$id,
      categorie = question$categorie,
      reponse = input$participant_response,
      stringsAsFactors = FALSE
    )
    
    responses <- rbind(responses, new_response)
    saveRDS(responses, "data/responses.rds")
    
    showNotification("✓ Vote enregistré avec succès !", type = "message")
    session$sendCustomMessage("reset_buttons", list())
  })
  
  # ========================================================================
  # ÉTAPE - AMÉLIORATIONS
  # ========================================================================
  
  output$step_ameliorations_content <- renderUI({
    question <- get_active_question()
    if (is.null(question)) return(NULL)
    
    propositions <- load_propositions_cached()
    propositions_ameliorations <- propositions %>%
      filter(question_id == question$id, type == "ameliorations") %>%
      arrange(desc(accord))
    
    tagList(
      tags$h3("🔄 Améliorations proposées", style = "color: #000091; margin-bottom: 20px;"),
      tags$p("Consultez les améliorations proposées par les participants et votez pour celles avec lesquelles vous êtes d'accord.", 
        style = "margin-bottom: 25px; color: #666;"),
      uiOutput("propositions_ameliorations_list", container = tags$div),
      render_new_proposition_form("ameliorations", question$id)
    )
  })
  
  output$propositions_ameliorations_list <- renderUI({
    question <- get_active_question()
    if (is.null(question)) return(NULL)
    
    propositions <- load_propositions_cached()
    propositions_ameliorations <- propositions %>%
      filter(question_id == question$id, type == "ameliorations") %>%
      arrange(desc(accord))
    
    render_propositions_ui(propositions_ameliorations, participant_id(), "ameliorations", question$id)
  })
  
  output$char_count_ameliorations <- renderText({
    text <- input$new_prop_ameliorations
    if (is.null(text)) return("0 / 500 caractères")
    paste0(nchar(text), " / 500 caractères")
  })
  
  observeEvent(input$submit_prop_ameliorations, {
    question <- get_active_question()
    text <- input$new_prop_ameliorations
    
    if (is.null(text) || nchar(trimws(text)) < 10) {
      showNotification("Votre proposition doit contenir au moins 10 caractères.", type = "warning")
      return()
    }
    
    if (nchar(text) > 500) {
      showNotification("Votre proposition ne peut pas dépasser 500 caractères.", type = "warning")
      return()
    }
    
    prop_id <- myshinyapp::add_proposition(question$id, "ameliorations", participant_id(), trimws(text))
    updateTextAreaInput(session, "new_prop_ameliorations", value = "")
    showNotification("✓ Votre proposition a été ajoutée avec succès !", type = "message")
  })
  
  # ========================================================================
  # GESTION DES VOTES SUR PROPOSITIONS
  # ========================================================================
  
  observeEvent(input$vote_action, {
    req(input$vote_action$prop_id, input$vote_action$vote)
    
    result <- myshinyapp::vote_proposition(
      participant_id = participant_id(),
      proposition_id = input$vote_action$prop_id,
      vote_type = input$vote_action$vote
    )
    
    if (result) {
      showNotification(
        paste("Vote enregistré:", 
          switch(input$vote_action$vote,
            "accord" = "D'accord ✓",
            "desaccord" = "Pas d'accord ✕",
            "passer" = "Passé −")),
        type = "message",
        duration = 2
      )
    }
  })
  
  # ========================================================================
  # ADMIN UI
  # ========================================================================
  
  output$admin_interface <- renderUI({
    tagList(
      # Bouton déconnexion
      tags$div(
        class = "text-center",
        style = "margin-bottom: 20px;",
        actionButton("admin_logout", "🚪 Déconnexion", class = "fr-btn fr-btn--secondary")
      ),
      
      # Contrôles de navigation
      uiOutput("admin_controls"),
      
      # Statistiques en temps réel
      tags$div(
        class = "dsfr-card",
        tags$h3("📊 Statistiques en temps réel", style = "color: #000091; margin-bottom: 20px;"),
        uiOutput("admin_stats"),
        plotlyOutput("admin_chart", height = "350px")
      ),
      
      # NOUVEAU : Gestion des votes de l'étape 3
      tags$div(
        class = "dsfr-card",
        style = "margin-top: 30px;",
        tags$h3("🗳️ Gestion des votes de cotation", style = "color: #000091; margin-bottom: 15px;"),
        tags$p("Réinitialisez les votes de l'étape 3 (FAVORABLE / NEUTRE / DÉFAVORABLE).", style = "margin-bottom: 20px; color: #666;"),
        
        # Statistiques des votes
        tags$div(
          uiOutput("votes_cotation_stats"),
          style = "margin-bottom: 20px; padding: 15px; background: #f6f6f6; border-radius: 0.5rem;"
        ),
        
        # Bouton de réinitialisation
        actionButton(
          "reset_votes_cotation", 
          "🗑️ Réinitialiser les votes de cotation", 
          class = "fr-btn",
          style = "background: #E1000F; color: white; width: 100%;"
        ),
        tags$p(
          "⚠️ Cette action supprimera uniquement les votes FAVORABLE/NEUTRE/DÉFAVORABLE, pas les propositions.",
          style = "margin-top: 15px; font-size: 0.9rem; color: #E1000F; font-weight: 500;"
        )
      ),
      
      # Gestion des propositions
      tags$div(
        class = "dsfr-card",
        style = "margin-top: 30px;",
        tags$h3("🗑️ Gestion des propositions", style = "color: #000091; margin-bottom: 15px;"),
        tags$p("Visualisez et modérez les propositions du système Local Polis.", style = "margin-bottom: 20px; color: #666;"),
        
        # Statistiques
        tags$div(
          uiOutput("propositions_stats"),
          style = "margin-bottom: 20px; padding: 15px; background: #f6f6f6; border-radius: 0.5rem;"
        ),
        
        # NOUVEAU : Liste des propositions avec boutons de suppression
        tags$div(
          tags$h4("📋 Liste des propositions", style = "color: #000091; margin-bottom: 15px; margin-top: 25px;"),
          uiOutput("propositions_list_display")
        ),
        
        # Bouton de réinitialisation globale (séparé visuellement)
        tags$div(
          style = "margin-top: 30px; padding-top: 20px; border-top: 2px solid #ddd;",
          actionButton(
            "reset_propositions", 
            "🗑️ Réinitialiser toutes les propositions", 
            class = "fr-btn",
            style = "background: #E1000F; color: white; width: 100%;"
          ),
          tags$p(
            "⚠️ Cette action est irréversible et supprimera toutes les propositions et votes.",
            style = "margin-top: 15px; font-size: 0.9rem; color: #E1000F; font-weight: 500;"
          )
        )
      ),
      
      # Export des données
      tags$div(
        class = "dsfr-card",
        style = "margin-top: 30px;",
        tags$h3("💾 Exporter les données", style = "color: #000091; margin-bottom: 20px;"),
        tags$p("Téléchargez toutes les données de la consultation au format ZIP.", style = "margin-bottom: 20px; color: #666;"),
        downloadButton("download_data", "📥 Télécharger les données (ZIP)", class = "fr-btn", style = "width: 100%;")
      )
    )
  })
  
  output$admin_stats <- renderUI({
    fluidRow(
      column(3, tags$div(class = "stats-card", style = "background: linear-gradient(135deg, #000091, #6A6AF4);",
        tags$span(class = "stat-number", textOutput("admin_total")),
        tags$span(class = "stat-label", "Réponses"))),
      column(3, tags$div(class = "stats-card", style = "background: linear-gradient(135deg, #00A95F, #009081);",
        tags$span(class = "stat-number", textOutput("admin_participants")),
        tags$span(class = "stat-label", "Participants"))),
      column(3, tags$div(class = "stats-card", style = "background: linear-gradient(135deg, #E4794A, #C3992A);",
        tags$span(class = "stat-number", textOutput("admin_question_num")),
        tags$span(class = "stat-label", "Question"))),
      column(3, tags$div(class = "stats-card", style = "background: linear-gradient(135deg, #E1000F, #CE614A);",
        tags$span(class = "stat-number", textOutput("admin_progress")),
        tags$span(class = "stat-label", "Progression")))
    )
  })
  
  # NOUVEAU : Statistiques des votes de cotation (étape 3)
  output$votes_cotation_stats <- renderUI({
    responses <- load_responses()
    
    n_total <- nrow(responses)
    n_favorable <- sum(responses$reponse == "FAVORABLE")
    n_neutre <- sum(responses$reponse == "NEUTRE")
    n_defavorable <- sum(responses$reponse == "DÉFAVORABLE")
    
    tagList(
      tags$div(
        style = "display: flex; justify-content: space-between; margin-bottom: 15px;",
        tags$div(tags$strong("Total votes de cotation : "), 
          tags$span(n_total, style = "color: #000091; font-weight: bold; font-size: 1.2rem;"))
      ),
      tags$div(
        style = "display: flex; gap: 15px;",
        tags$div(style = "flex: 1; padding: 10px; background: white; border-radius: 0.25rem; text-align: center;",
          tags$div(style = "font-size: 1.5rem; color: #00A95F; font-weight: bold;", n_favorable),
          tags$div(style = "font-size: 0.85rem; color: #666;", "Favorables")),
        tags$div(style = "flex: 1; padding: 10px; background: white; border-radius: 0.25rem; text-align: center;",
          tags$div(style = "font-size: 1.5rem; color: #666666; font-weight: bold;", n_neutre),
          tags$div(style = "font-size: 0.85rem; color: #666;", "Neutres")),
        tags$div(style = "flex: 1; padding: 10px; background: white; border-radius: 0.25rem; text-align: center;",
          tags$div(style = "font-size: 1.5rem; color: #E1000F; font-weight: bold;", n_defavorable),
          tags$div(style = "font-size: 0.85rem; color: #666;", "Défavorables"))
      )
    )
  })
  
  output$propositions_stats <- renderUI({
    # Forcer le rafraîchissement avec le trigger
    polis_refresh_trigger()
    
    propositions <- myshinyapp::load_propositions()
    votes <- myshinyapp::load_votes()
    
    n_propositions <- nrow(propositions)
    n_votes <- nrow(votes)
    n_positifs <- sum(propositions$type == "positifs")
    n_negatifs <- sum(propositions$type == "negatifs")
    n_ameliorations <- sum(propositions$type == "ameliorations")
    
    tagList(
      tags$div(
        style = "display: flex; justify-content: space-between; margin-bottom: 10px;",
        tags$div(tags$strong("Total propositions : "), 
          tags$span(n_propositions, style = "color: #000091; font-weight: bold; font-size: 1.2rem;")),
        tags$div(tags$strong("Total votes : "), 
          tags$span(n_votes, style = "color: #00A95F; font-weight: bold; font-size: 1.2rem;"))
      ),
      tags$div(
        style = "display: flex; gap: 15px; margin-top: 15px;",
        tags$div(style = "flex: 1; padding: 10px; background: white; border-radius: 0.25rem; text-align: center;",
          tags$div(style = "font-size: 1.5rem; color: #00A95F; font-weight: bold;", n_positifs),
          tags$div(style = "font-size: 0.85rem; color: #666;", "Positifs")),
        tags$div(style = "flex: 1; padding: 10px; background: white; border-radius: 0.25rem; text-align: center;",
          tags$div(style = "font-size: 1.5rem; color: #E1000F; font-weight: bold;", n_negatifs),
          tags$div(style = "font-size: 0.85rem; color: #666;", "Négatifs")),
        tags$div(style = "flex: 1; padding: 10px; background: white; border-radius: 0.25rem; text-align: center;",
          tags$div(style = "font-size: 1.5rem; color: #000091; font-weight: bold;", n_ameliorations),
          tags$div(style = "font-size: 0.85rem; color: #666;", "Améliorations"))
      )
    )
  })
  
  # NOUVEAU : Affichage de la liste des propositions avec rafraîchissement en temps réel
  output$propositions_list_display <- renderUI({
    # Forcer le rafraîchissement avec le trigger
    polis_refresh_trigger()
    
    propositions <- myshinyapp::load_propositions()
    
    if (nrow(propositions) == 0) {
      return(tags$div(
        style = "text-align: center; padding: 30px; color: #666; background: #f6f6f6; border-radius: 0.5rem;",
        tags$p(style = "margin: 0; font-size: 1rem;", "📝 Aucune proposition pour le moment.")
      ))
    }
    
    # Créer la liste des propositions
    prop_items <- lapply(1:nrow(propositions), function(i) {
      prop <- propositions[i, ]
      
      # Déterminer le type et la couleur
      type_info <- switch(prop$type,
        "positifs" = list(label = "✅ Impact positif", color = "#00A95F"),
        "negatifs" = list(label = "⚠️ Impact négatif", color = "#E1000F"),
        "ameliorations" = list(label = "💡 Amélioration", color = "#000091")
      )
      
      tags$div(
        style = "border: 1px solid #ddd; border-radius: 0.5rem; padding: 15px; margin-bottom: 15px; background: white;",
        
        # En-tête avec type et boutons d'action
        tags$div(
          style = "display: flex; justify-content: space-between; align-items: center; margin-bottom: 10px;",
          tags$div(
            style = paste0("font-weight: bold; color: ", type_info$color, "; font-size: 0.9rem;"),
            type_info$label
          ),
          tags$div(
            style = "display: flex; gap: 8px;",
            # Bouton Modérer (réinitialiser les votes)
            actionButton(
              inputId = paste0("moderate_prop_", prop$id),
              label = "🔄 Modérer",
              class = "btn-sm",
              style = "background: #000091; color: white; border: none; padding: 5px 12px; border-radius: 0.25rem; font-size: 0.85rem; cursor: pointer;"
            ),
            # Bouton Supprimer
            actionButton(
              inputId = paste0("delete_prop_", prop$id),
              label = "🗑️ Supprimer",
              class = "btn-sm",
              style = "background: #E1000F; color: white; border: none; padding: 5px 12px; border-radius: 0.25rem; font-size: 0.85rem; cursor: pointer;"
            )
          )
        ),
        
        # Texte de la proposition
        tags$div(
          style = "margin-bottom: 10px; padding: 10px; background: #f6f6f6; border-radius: 0.25rem;",
          tags$p(style = "margin: 0; font-size: 0.95rem;", prop$texte)
        ),
        
        # Statistiques
        tags$div(
          style = "display: flex; gap: 15px; font-size: 0.85rem; color: #666;",
          tags$div(
            tags$span(style = "color: #00A95F; font-weight: bold;", "✓ ", prop$accord),
            " D'accord"
          ),
          tags$div(
            tags$span(style = "color: #E1000F; font-weight: bold;", "✕ ", prop$desaccord),
            " Pas d'accord"
          ),
          tags$div(
            tags$span(style = "color: #666; font-weight: bold;", "− ", prop$passer),
            " Passer"
          ),
          tags$div(
            style = "margin-left: auto;",
            tags$span(style = "color: #000091; font-weight: bold;",
              myshinyapp::calculate_consensus_score(prop$accord, prop$desaccord, prop$passer), "% accord")
          )
        ),
        
        # Métadonnées
        tags$div(
          style = "margin-top: 10px; font-size: 0.75rem; color: #999;",
          paste0("ID: ", substr(prop$id, 1, 20), "... | ", 
                 format(as.POSIXct(prop$timestamp), "%d/%m/%Y %H:%M"))
        )
      )
    })
    
    tags$div(
      style = "max-height: 600px; overflow-y: auto;",
      prop_items
    )
  })
  
  # NOUVEAU : Gestion de la suppression individuelle des propositions
  observe({
    # Forcer la mise à jour avec le trigger
    polis_refresh_trigger()
    
    propositions <- myshinyapp::load_propositions()
    
    if (nrow(propositions) > 0) {
      lapply(propositions$id, function(prop_id) {
        # NOUVEAU : Observer le clic sur le bouton de modération (réinitialiser les votes)
        observeEvent(input[[paste0("moderate_prop_", prop_id)]], {
          showModal(modalDialog(
            title = "🔄 Modérer cette proposition",
            tags$div(
              tags$p("Voulez-vous réinitialiser tous les votes de cette proposition ?", 
                style = "margin-bottom: 15px; font-size: 1rem;"),
              tags$p("Cette action supprimera tous les votes (D'accord, Pas d'accord, Passer) mais conservera la proposition.", 
                style = "color: #000091; font-weight: 500; font-size: 0.9rem;"),
              tags$div(
                style = "background: #f6f6f6; padding: 10px; border-radius: 0.25rem; margin-top: 15px;",
                tags$ul(style = "margin: 0; padding-left: 20px; font-size: 0.9rem;",
                  tags$li("Tous les votes seront supprimés"),
                  tags$li("Les compteurs seront remis à 0"),
                  tags$li("La proposition sera conservée")
                )
              )
            ),
            footer = tagList(
              modalButton("Annuler"),
              actionButton(
                paste0("confirm_moderate_", prop_id), 
                "🔄 Réinitialiser les votes",
                style = "background: #000091; color: white; border: none; padding: 0.5rem 1rem; border-radius: 0.25rem; cursor: pointer;"
              )
            ),
            size = "m"
          ))
        }, ignoreInit = TRUE, ignoreNULL = TRUE)
        
        # NOUVEAU : Observer la confirmation de modération
        observeEvent(input[[paste0("confirm_moderate_", prop_id)]], {
          # Charger les propositions
          propositions <- myshinyapp::load_propositions()
          prop_index <- which(propositions$id == prop_id)
          
          if (length(prop_index) > 0) {
            # Remettre les compteurs à zéro
            propositions$accord[prop_index] <- 0
            propositions$desaccord[prop_index] <- 0
            propositions$passer[prop_index] <- 0
            saveRDS(propositions, "data/propositions.rds")
          }
          
          # Supprimer tous les votes associés à cette proposition
          votes <- myshinyapp::load_votes()
          votes <- votes[votes$proposition_id != prop_id, ]
          saveRDS(votes, "data/votes.rds")
          
          # Invalider le cache
          polis_cache$positifs <- NULL
          polis_cache$negatifs <- NULL
          polis_cache$ameliorations <- NULL
          polis_cache$last_update <- Sys.time()
          
          # Forcer le rafraîchissement
          polis_refresh_trigger(polis_refresh_trigger() + 1)
          
          removeModal()
          showNotification("✓ Votes de la proposition réinitialisés avec succès", type = "message", duration = 3)
        }, ignoreInit = TRUE, ignoreNULL = TRUE)
        
        # Observer le clic sur le bouton de suppression
        observeEvent(input[[paste0("delete_prop_", prop_id)]], {
          showModal(modalDialog(
            title = "⚠️ Confirmer la suppression",
            tags$div(
              tags$p("Êtes-vous sûr de vouloir supprimer cette proposition ?", 
                style = "margin-bottom: 15px; font-size: 1rem;"),
              tags$p("Cette action supprimera également tous les votes associés.", 
                style = "color: #E1000F; font-weight: 500; font-size: 0.9rem;")
            ),
            footer = tagList(
              modalButton("Annuler"),
              actionButton(
                paste0("confirm_delete_", prop_id), 
                "🗑️ Supprimer",
                style = "background: #E1000F; color: white; border: none; padding: 0.5rem 1rem; border-radius: 0.25rem; cursor: pointer;"
              )
            ),
            size = "m"
          ))
        }, ignoreInit = TRUE, ignoreNULL = TRUE)
        
        # Observer la confirmation de suppression
        observeEvent(input[[paste0("confirm_delete_", prop_id)]], {
          # Supprimer la proposition
          propositions <- myshinyapp::load_propositions()
          propositions <- propositions[propositions$id != prop_id, ]
          saveRDS(propositions, "data/propositions.rds")
          
          # Supprimer les votes associés
          votes <- myshinyapp::load_votes()
          votes <- votes[votes$proposition_id != prop_id, ]
          saveRDS(votes, "data/votes.rds")
          
          # Invalider le cache
          polis_cache$positifs <- NULL
          polis_cache$negatifs <- NULL
          polis_cache$ameliorations <- NULL
          polis_cache$last_update <- Sys.time()
          
          # Forcer le rafraîchissement
          polis_refresh_trigger(polis_refresh_trigger() + 1)
          
          removeModal()
          showNotification("✓ Proposition supprimée avec succès", type = "message", duration = 3)
        }, ignoreInit = TRUE, ignoreNULL = TRUE)
      })
    }
  })
  
  output$admin_controls <- renderUI({
    tags$div(
      class = "dsfr-card", style = "margin-top: 30px;",
      tags$h3("🎮 Contrôle de la consultation", style = "color: #000091; margin-bottom: 25px;"),
      
      conditionalPanel(
        condition = "output.session_not_started",
        tags$div(style = "text-align: center; padding: 40px;",
          tags$div(style = "font-size: 80px; margin-bottom: 20px;", "🚀"),
          tags$h3("Session non démarrée", style = "color: #000091;"),
          tags$p("Cliquez pour lancer la première question", style = "margin-bottom: 30px;"),
          actionButton("start_session", "🚀 Démarrer la consultation", 
            class = "fr-btn", style = "font-size: 1.1rem; padding: 1rem 2rem;")
        )
      ),
      
      conditionalPanel(
        condition = "!output.session_not_started && !output.session_finished",
        tags$div(style = "background: #f6f6f6; padding: 25px; border-radius: 0.5rem; margin-bottom: 25px;",
          tags$h4("Question active :", style = "color: #000091; margin-bottom: 15px;"),
          uiOutput("admin_question_badge"),
          tags$p(textOutput("admin_question_text"), 
            style = "font-size: 1.15rem; font-weight: 600; margin-top: 15px;"),
          tags$div(style = "margin-top: 20px; padding: 15px; background: white; border-radius: 0.5rem; border-left: 4px solid #000091;",
            tags$strong("Étape actuelle : "), textOutput("admin_current_step", inline = TRUE))
        ),
        
        tags$h4("📋 Navigation par étapes", style = "color: #000091; margin: 25px 0 15px 0;"),
        tags$div(class = "admin-controls",
          actionButton("step_positifs", "👍 1. Impacts positifs", class = "fr-btn fr-btn--success"),
          actionButton("step_negatifs", "👎 2. Impacts négatifs", class = "fr-btn fr-btn--success"),
          actionButton("step_vote", "🗳️ 3. Vote", class = "fr-btn fr-btn--success"),
          actionButton("step_ameliorations", "🔄 4. Améliorations", class = "fr-btn fr-btn--success")
        ),
        
        tags$hr(style = "margin: 30px 0;"),
        
        tags$h4("🔀 Navigation entre questions", style = "color: #000091; margin: 25px 0 15px 0;"),
        tags$div(style = "display: flex; gap: 15px; flex-wrap: wrap;",
          actionButton("prev_question", "⬅ Question précédente", 
            class = "fr-btn fr-btn--secondary", style = "flex: 1;"),
          actionButton("next_question", "Question suivante ➡", 
            class = "fr-btn", style = "flex: 1;"),
          actionButton("end_session", "🏁 Terminer", 
            class = "fr-btn fr-btn--secondary", style = "flex: 1;")
        )
      ),
      
      conditionalPanel(
        condition = "output.session_finished",
        tags$div(style = "text-align: center; padding: 40px;",
          tags$div(style = "font-size: 60px; color: #00A95F; margin-bottom: 15px;", "✓"),
          tags$h3("Session terminée", style = "color: #00A95F; margin-bottom: 25px;"),
          actionButton("restart_session", "🔄 Nouvelle session", class = "fr-btn fr-btn--secondary")
        )
      )
    )
  })
  
  output$admin_question_badge <- renderUI({
    question <- get_active_question()
    if (is.null(question)) return(NULL)
    
    color <- myshinyapp::get_category_color(question$categorie)
    tags$div(class = "categorie-badge",
      style = paste0("background: ", color, "; color: white;"),
      question$categorie)
  })
  
  output$admin_question_text <- renderText({
    question <- get_active_question()
    if (is.null(question)) return("Aucune question active")
    question$texte
  })
  
  output$admin_current_step <- renderText({
    active <- load_active_question()
    if (is.null(active$step)) return("Aucune")
    myshinyapp::get_step_name(active$step)
  })
  
  output$session_not_started <- reactive({
    active <- load_active_question()
    is.null(active$question_id) || active$question_num == 0
  })
  outputOptions(output, "session_not_started", suspendWhenHidden = FALSE)
  
  output$session_finished <- reactive({
    active <- load_active_question()
    !is.null(active$question_num) && active$question_num > length(all_questions)
  })
  outputOptions(output, "session_finished", suspendWhenHidden = FALSE)
  
  # ========================================================================
  # ADMIN CONTROLS
  # ========================================================================
  
  observeEvent(input$start_session, {
    save_active_question(all_questions[[1]]$id, 1, 1)
    showNotification("✓ Consultation démarrée - Étape 1: Impacts positifs", type = "message")
  })
  
  observeEvent(input$step_positifs, {
    active <- load_active_question()
    if (!is.null(active$question_id)) {
      save_active_question(active$question_id, active$question_num, 1)
      showNotification("✓ Affichage: Impacts positifs", type = "message")
    }
  })
  
  observeEvent(input$step_negatifs, {
    active <- load_active_question()
    if (!is.null(active$question_id)) {
      save_active_question(active$question_id, active$question_num, 2)
      showNotification("✓ Affichage: Impacts négatifs", type = "message")
    }
  })
  
  observeEvent(input$step_vote, {
    active <- load_active_question()
    if (!is.null(active$question_id)) {
      save_active_question(active$question_id, active$question_num, 3)
      showNotification("✓ Affichage: Vote", type = "message")
    }
  })
  
  observeEvent(input$step_ameliorations, {
    active <- load_active_question()
    if (!is.null(active$question_id)) {
      save_active_question(active$question_id, active$question_num, 4)
      showNotification("✓ Affichage: Améliorations", type = "message")
    }
  })
  
  observeEvent(input$next_question, {
    active <- load_active_question()
    next_num <- active$question_num + 1
    
    if (next_num <= length(all_questions)) {
      save_active_question(all_questions[[next_num]]$id, next_num, 1)
      showNotification(paste("Question", next_num, "activée - Étape 1"), type = "message")
    } else {
      save_active_question(NULL, next_num, 0)
      showNotification("Consultation terminée", type = "message")
    }
  })
  
  observeEvent(input$prev_question, {
    active <- load_active_question()
    prev_num <- active$question_num - 1
    
    if (prev_num >= 1) {
      save_active_question(all_questions[[prev_num]]$id, prev_num, 1)
      showNotification(paste("Retour à la question", prev_num), type = "message")
    }
  })
  
  observeEvent(input$end_session, {
    showModal(modalDialog(
      title = "Confirmer la fin",
      "Êtes-vous sûr de vouloir terminer la consultation ?",
      footer = tagList(
        modalButton("Annuler"),
        actionButton("confirm_end", "Terminer", 
          style = "background: #000091; color: white; border: none; padding: 0.75rem 1.5rem; border-radius: 0.25rem; font-weight: 500; cursor: pointer;")
      )
    ))
  })
  
  observeEvent(input$confirm_end, {
    save_active_question(NULL, length(all_questions) + 1, 0)
    removeModal()
    showNotification("✓ Consultation terminée", type = "message")
  })
  
  observeEvent(input$restart_session, {
    save_active_question(NULL, 0, 0)
    polis_cache$positifs <- NULL
    polis_cache$negatifs <- NULL
    polis_cache$ameliorations <- NULL
    showNotification("Session réinitialisée", type = "message")
  })
  
  # ========================================================================
  # RÉINITIALISATION DES VOTES DE COTATION (ÉTAPE 3)
  # ========================================================================
  
  observeEvent(input$reset_votes_cotation, {
    showModal(modalDialog(
      title = "⚠️ Confirmer la suppression",
      tags$div(
        tags$p("Êtes-vous sûr de vouloir supprimer TOUS les votes de cotation (FAVORABLE/NEUTRE/DÉFAVORABLE) ?", 
          style = "font-size: 1.1rem; margin-bottom: 15px;"),
        tags$p("Cette action est IRRÉVERSIBLE.", 
          style = "color: #E1000F; font-weight: bold; margin-bottom: 15px;"),
        tags$div(
          style = "background: #f6f6f6; padding: 15px; border-radius: 0.5rem; margin-bottom: 20px;",
          tags$ul(style = "margin: 0; padding-left: 20px;",
            tags$li("Tous les votes FAVORABLE/NEUTRE/DÉFAVORABLE seront supprimés"),
            tags$li("Les propositions et leurs votes seront conservés")
          )
        )
      ),
      footer = tagList(
        modalButton("Annuler"),
        actionButton("confirm_reset_votes_cotation", "🗑️ Confirmer la suppression", 
          style = "background: #E1000F; color: white; border: none; padding: 0.75rem 1.5rem; border-radius: 0.25rem; font-weight: 500; cursor: pointer;")
      ),
      size = "m"
    ))
  })
  
  observeEvent(input$confirm_reset_votes_cotation, {
    # Créer un dataframe vide pour les réponses
    responses_df <- data.frame(
      timestamp = character(),
      participant_id = character(),
      question_id = character(),
      categorie = character(),
      reponse = character(),
      stringsAsFactors = FALSE
    )
    
    # Sauvegarder le fichier vide
    saveRDS(responses_df, "data/responses.rds")
    
    removeModal()
    showNotification("✓ Tous les votes de cotation ont été supprimés", type = "message", duration = 5)
  })
  
  # ========================================================================
  # RÉINITIALISATION DES PROPOSITIONS (CORRIGÉ)
  # ========================================================================
  
  observeEvent(input$reset_propositions, {
    showModal(modalDialog(
      title = "⚠️ Confirmer la suppression",
      tags$div(
        tags$p("Êtes-vous sûr de vouloir supprimer TOUTES les propositions et votes ?", 
          style = "font-size: 1.1rem; margin-bottom: 15px;"),
        tags$p("Cette action est IRRÉVERSIBLE.", 
          style = "color: #E1000F; font-weight: bold; margin-bottom: 15px;"),
        tags$div(
          style = "background: #f6f6f6; padding: 15px; border-radius: 0.5rem; margin-bottom: 20px;",
          tags$ul(style = "margin: 0; padding-left: 20px;",
            tags$li("Toutes les propositions seront supprimées"),
            tags$li("Tous les votes seront supprimés"),
            tags$li("Les réponses classiques (favorable/neutre/défavorable) seront conservées")
          )
        )
      ),
      footer = tagList(
        modalButton("Annuler"),
        actionButton("confirm_reset_propositions", "🗑️ Confirmer la suppression", 
          style = "background: #E1000F; color: white; border: none; padding: 0.75rem 1.5rem; border-radius: 0.25rem; font-weight: 500; cursor: pointer;")
      ),
      size = "m"
    ))
  })
  
  # CORRECTION: Réinitialiser aussi les compteurs accord/desaccord/passer dans les propositions
  observeEvent(input$confirm_reset_propositions, {
    # Créer des fichiers vides avec les compteurs à zéro
    propositions_df <- data.frame(
      id = character(),
      question_id = character(),
      type = character(),
      participant_id = character(),
      texte = character(),
      timestamp = character(),
      accord = integer(),
      desaccord = integer(),
      passer = integer(),
      stringsAsFactors = FALSE
    )
    
    votes_df <- data.frame(
      participant_id = character(),
      proposition_id = character(),
      vote = character(),
      timestamp = character(),
      stringsAsFactors = FALSE
    )
    
    # Sauvegarder les fichiers vides
    saveRDS(propositions_df, "data/propositions.rds")
    saveRDS(votes_df, "data/votes.rds")
    
    # Réinitialiser le cache
    polis_cache$positifs <- NULL
    polis_cache$negatifs <- NULL
    polis_cache$ameliorations <- NULL
    polis_cache$last_update <- Sys.time()
    
    # CORRECTION : Forcer le rafraîchissement immédiat
    polis_refresh_trigger(polis_refresh_trigger() + 1)
    
    removeModal()
    showNotification("✓ Toutes les propositions et votes ont été supprimés", type = "message", duration = 5)
  })
  
  # ========================================================================
  # STATISTIQUES
  # ========================================================================
  
  get_current_stats <- reactive({
    responses <- load_responses()
    question <- get_active_question()
    
    if (is.null(question) || nrow(responses) == 0) {
      return(list(total = 0, stats = data.frame()))
    }
    
    current_responses <- responses %>% filter(question_id == question$id)
    
    if (nrow(current_responses) == 0) {
      return(list(total = 0, stats = data.frame()))
    }
    
    stats <- current_responses %>%
      group_by(reponse) %>%
      summarise(count = n(), .groups = "drop") %>%
      mutate(pourcentage = round(count / sum(count) * 100, 1))
    
    list(total = nrow(current_responses), stats = stats)
  })
  
  output$live_total <- renderText({ as.character(get_current_stats()$total) })
  
  output$live_favorable <- renderText({
    stats <- get_current_stats()$stats
    if (nrow(stats) == 0) return("0%")
    fav <- stats %>% filter(reponse == "FAVORABLE")
    if (nrow(fav) == 0) return("0%")
    paste0(fav$pourcentage, "%")
  })
  
  output$live_neutre <- renderText({
    stats <- get_current_stats()$stats
    if (nrow(stats) == 0) return("0%")
    neu <- stats %>% filter(reponse == "NEUTRE")
    if (nrow(neu) == 0) return("0%")
    paste0(neu$pourcentage, "%")
  })
  
  output$live_defavorable <- renderText({
    stats <- get_current_stats()$stats
    if (nrow(stats) == 0) return("0%")
    def <- stats %>% filter(reponse == "DÉFAVORABLE")
    if (nrow(def) == 0) return("0%")
    paste0(def$pourcentage, "%")
  })
  
  output$admin_total <- renderText({ as.character(nrow(load_responses())) })
  output$admin_participants <- renderText({ as.character(length(unique(load_responses()$participant_id))) })
  
  output$admin_question_num <- renderText({
    active <- load_active_question()
    if (is.null(active$question_num) || active$question_num == 0) return("-")
    if (active$question_num > length(all_questions)) return("Fin")
    paste(active$question_num, "/", length(all_questions))
  })
  
  output$admin_progress <- renderText({
    active <- load_active_question()
    if (is.null(active$question_num) || active$question_num == 0) return("0%")
    if (active$question_num > length(all_questions)) return("100%")
    paste0(round(active$question_num / length(all_questions) * 100), "%")
  })
  
  output$admin_chart <- renderPlotly({
    stats <- get_current_stats()
    
    if (nrow(stats$stats) == 0) {
      plot_ly(type = "scatter", mode = "markers") %>% 
        add_trace(x = c(0), y = c(0), marker = list(size = 0)) %>%
        layout(
          title = list(text = "Aucune réponse pour le moment", font = list(size = 16, color = "#666")),
          xaxis = list(visible = FALSE),
          yaxis = list(visible = FALSE),
          paper_bgcolor = "white",
          plot_bgcolor = "white",
          showlegend = FALSE,
          margin = list(t = 50, b = 10, l = 10, r = 10)
        )
    } else {
      stats$stats$reponse <- factor(stats$stats$reponse, levels = c("FAVORABLE", "NEUTRE", "DÉFAVORABLE"))
      
      colors_map <- c("FAVORABLE" = "#00A95F", "NEUTRE" = "#666666", "DÉFAVORABLE" = "#E1000F")
      
      plot_ly(
        data = stats$stats,
        type = "pie",
        labels = ~reponse, 
        values = ~count,
        marker = list(colors = ~colors_map[reponse]),
        textposition = "inside",
        textinfo = "label+percent",
        textfont = list(size = 14, color = "white", family = "Marianne, Arial, sans-serif"),
        hovertemplate = "%{label}<br>%{value} réponses<br>%{percent}<extra></extra>",
        hole = 0
      ) %>%
        layout(
          showlegend = TRUE,
          legend = list(
            font = list(size = 12, family = "Marianne, Arial, sans-serif"),
            orientation = "h",
            x = 0.5,
            xanchor = "center",
            y = -0.1
          ),
          paper_bgcolor = "white",
          plot_bgcolor = "white",
          font = list(family = "Marianne, Arial, sans-serif"),
          margin = list(t = 20, b = 60, l = 10, r = 10)
        )
    }
  })
  
  # ========================================================================
  # EXPORT DES DONNÉES
  # ========================================================================
  
  output$download_data <- downloadHandler(
    filename = function() {
      paste0("consultation_bte_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".zip")
    },
    content = function(file) {
      responses <- load_responses()
      propositions <- myshinyapp::load_propositions()
      votes <- myshinyapp::load_votes()
      
      temp_dir <- file.path(tempdir(), paste0("consultation_", format(Sys.time(), "%Y%m%d%H%M%S")))
      dir.create(temp_dir, showWarnings = FALSE)
      
      csv_reponses <- file.path(temp_dir, "reponses.csv")
      csv_propositions <- file.path(temp_dir, "propositions.csv")
      csv_votes <- file.path(temp_dir, "votes.csv")
      
      write.csv(responses, csv_reponses, row.names = FALSE, fileEncoding = "UTF-8")
      write.csv(propositions, csv_propositions, row.names = FALSE, fileEncoding = "UTF-8")
      write.csv(votes, csv_votes, row.names = FALSE, fileEncoding = "UTF-8")
      
      files_to_zip <- c("reponses.csv", "propositions.csv", "votes.csv")
      old_wd <- getwd()
      setwd(temp_dir)
      
      tryCatch({
        zip::zip(zipfile = file, files = files_to_zip, mode = "cherry-pick")
      }, error = function(e) {
        utils::zip(zipfile = file, files = files_to_zip, flags = "-r9Xq")
      }, finally = {
        setwd(old_wd)
      })
      
      unlink(temp_dir, recursive = TRUE)
    }
  )
}

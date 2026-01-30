# ============================================================================
# UI - CONSULTATION BTE avec Design DSFR
# ============================================================================

library(shiny)

# Configuration
PROJECT_IMAGE_URL <- "projet.png"
PROJECT_IMAGE_2_URL <- "projet.2.png"
PROJECT_NAME <- "Webinaire Atelier Boussole de la Transition Écologique"

ui <- fluidPage(
  # CSS DSFR depuis CDN
  tags$head(
    tags$link(
      rel = "stylesheet",
      href = "https://cdn.jsdelivr.net/npm/@gouvfr/dsfr@1.11/dist/dsfr.min.css"
    ),
    tags$script(
      src = "https://cdn.jsdelivr.net/npm/@gouvfr/dsfr@1.11/dist/dsfr.module.min.js",
      type = "module"
    ),
    tags$link(rel = "stylesheet", href = "custom.css"),
    
    # Script pour empêcher le scintillement
    tags$script(HTML("
      // Désactiver le recalcul automatique pour éviter les scintillements
      $(document).on('shiny:recalculating', function(event) {
        if (event.target && event.target.id && event.target.id.includes('propositions')) {
          event.preventDefault();
        }
      });
      
      // Gestion des boutons de réponse
      $(document).on('click', '.response-btn', function() {
        $('.response-btn').removeClass('selected');
        $(this).addClass('selected');
      });
      
      // Gestion optimisée des boutons de vote
      $(document).on('click', '.vote-btn', function() {
        var propId = $(this).data('prop-id');
        var voteType = $(this).data('vote-type');
        
        $('.vote-btn[data-prop-id=\"' + propId + '\"]').removeClass('active');
        $(this).addClass('active');
      });
      
      Shiny.addCustomMessageHandler('reset_buttons', function(msg) {
        $('.response-btn').removeClass('selected');
      });
    "))
  ),
  
  tags$div(
    class = "main-container",
    
    tabsetPanel(
      id = "main_tabs",
      type = "tabs",
      
      # ======================================================================
      # ONGLET PARTICIPANT
      # ======================================================================
      tabPanel(
        title = "👤 Participant",
        value = "participant",
        
        # État 1: En attente
        conditionalPanel(
          condition = "output.participant_waiting",
          tags$div(
            class = "dsfr-card text-center",
            style = "padding: 60px;",
            tags$div(style = "font-size: 80px; margin-bottom: 20px;", "⏳"),
            tags$h2("Session en attente", style = "color: #000091;"),
            tags$p("L'animateur n'a pas encore lancé la consultation."),
            tags$p("Cette page se mettra à jour automatiquement...", style = "color: #666;")
          )
        ),
        
        # État 2: Question active
        conditionalPanel(
          condition = "output.participant_has_question",
          
          # Barre de progression
          tags$div(
            class = "progress-bar-custom",
            tags$div(class = "progress-fill", style = textOutput("progress_style", inline = TRUE))
          ),
          tags$div(
            class = "text-center",
            style = "font-weight: bold; margin-bottom: 30px; color: #666; font-size: 1.2rem;",
            textOutput("progress_text")
          ),
          
          # Indicateur d'étapes
          uiOutput("step_indicator"),
          
          # Layout question
          fluidRow(
            # Image projet + DESCRIPTION (2/5)
            column(
              width = 5,
              tags$div(
                class = "dsfr-card",
                style = "padding: 0;",
                tags$img(src = PROJECT_IMAGE_URL, style = "width: 100%; border-radius: 0.5rem 0.5rem 0 0;"),
                uiOutput("project_description"),
                tags$img(src = PROJECT_IMAGE_2_URL, style = "width: 100%; border-radius: 0.5rem 0.5rem 0 0;")
              )
            ),
            
            # Colonne droite: Question et contenu selon l'étape (3/5)
            column(
              width = 7,
              tags$div(
                class = "dsfr-card",
                uiOutput("question_badge"),
                uiOutput("question_display"),
                
                # ÉTAPE 1: IMPACTS POSITIFS
                conditionalPanel(
                  condition = "output.show_step_positifs",
                  uiOutput("step_positifs_content")
                ),
                
                # ÉTAPE 2: IMPACTS NÉGATIFS
                conditionalPanel(
                  condition = "output.show_step_negatifs",
                  uiOutput("step_negatifs_content")
                ),
                
                # ÉTAPE 3: VOTE
                conditionalPanel(
                  condition = "output.show_step_vote",
                  uiOutput("step_vote_content")
                ),
                
                # ÉTAPE 4: AMÉLIORATIONS
                conditionalPanel(
                  condition = "output.show_step_ameliorations",
                  uiOutput("step_ameliorations_content")
                )
              )
            )
          )
        ),
        
        # État 3: Session terminée
        conditionalPanel(
          condition = "output.participant_finished",
          tags$div(
            class = "dsfr-card text-center",
            style = "padding: 80px;",
            tags$div(style = "font-size: 100px; margin-bottom: 25px;", "✓"),
            tags$h2("Consultation terminée", style = "color: #00A95F;"),
            tags$p("Merci pour votre participation !", style = "font-size: 1.3rem; color: #666;")
          )
        )
      ),
      
      # ======================================================================
      # ONGLET ANIMATEUR
      # ======================================================================
      tabPanel(
        title = "👨‍💼 Animateur",
        value = "admin",
        
        # Connexion admin
        conditionalPanel(
          condition = "!output.admin_authenticated",
          tags$div(
            class = "dsfr-card text-center",
            style = "max-width: 500px; margin: 100px auto; padding: 40px;",
            tags$h2("🔐 Accès Animateur", style = "color: #000091; margin-bottom: 30px;"),
            passwordInput("admin_password", "Mot de passe", width = "100%"),
            actionButton("admin_login", "Se connecter", 
                        class = "fr-btn", style = "width: 100%; margin-top: 15px;"),
            uiOutput("login_error")
          )
        ),
        
        # Interface admin
        conditionalPanel(
          condition = "output.admin_authenticated",
          uiOutput("admin_interface")
        )
      )
    )
  )
)

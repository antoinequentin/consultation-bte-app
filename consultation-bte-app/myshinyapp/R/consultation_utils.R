# ============================================================================
# FONCTIONS DE GESTION DES PROPOSITIONS
# ============================================================================

#' Initialize Propositions File
#'
#' @description Create the propositions data file if it doesn't exist
#' @export
initialize_propositions <- function() {
  if (!file.exists("data/propositions.rds")) {
    propositions_df <- data.frame(
      id = character(),
      question_id = character(),
      type = character(), # "positifs", "negatifs", "ameliorations"
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
      vote = character(), # "accord", "desaccord", "passer"
      timestamp = character(),
      stringsAsFactors = FALSE
    )
    saveRDS(votes_df, "data/votes.rds")
  }
}

#' Load Propositions
#'
#' @description Load propositions from RDS file
#' @return Data frame with propositions
#' @export
load_propositions <- function() {
  if (file.exists("data/propositions.rds")) {
    readRDS("data/propositions.rds")
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

#' Load Votes
#'
#' @description Load votes from RDS file
#' @return Data frame with votes
#' @export
load_votes <- function() {
  if (file.exists("data/votes.rds")) {
    readRDS("data/votes.rds")
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

#' Add Proposition
#'
#' @param question_id Question ID
#' @param type Type of proposition (positifs, negatifs, ameliorations)
#' @param participant_id Participant ID
#' @param texte Proposition text
#' @return Proposition ID
#' @export
add_proposition <- function(question_id, type, participant_id, texte) {
  initialize_propositions()
  
  # Simple lock to avoid concurrency issues
  lock_file <- "data/.propositions.lock"
  
  # Wait for lock to be released (max 5 seconds)
  timeout <- Sys.time() + 5
  while (file.exists(lock_file) && Sys.time() < timeout) {
    Sys.sleep(0.1)
  }
  
  # Create lock
  writeLines("locked", lock_file)
  
  tryCatch({
    propositions <- load_propositions()
    
    new_prop <- data.frame(
      id = paste0("prop_", format(Sys.time(), "%Y%m%d%H%M%S"), "_", sample(1000:9999, 1)),
      question_id = question_id,
      type = type,
      participant_id = participant_id,
      texte = texte,
      timestamp = as.character(Sys.time()),
      accord = 0,
      desaccord = 0,
      passer = 0,
      stringsAsFactors = FALSE
    )
    
    propositions <- rbind(propositions, new_prop)
    saveRDS(propositions, "data/propositions.rds")
    
    return(new_prop$id)
  }, finally = {
    # Release lock
    if (file.exists(lock_file)) {
      unlink(lock_file)
    }
  })
}

#' Vote for Proposition
#'
#' @param participant_id Participant ID
#' @param proposition_id Proposition ID
#' @param vote_type Vote type (accord, desaccord, passer)
#' @return TRUE if successful
#' @export
vote_proposition <- function(participant_id, proposition_id, vote_type) {
  initialize_propositions()
  
  # Lock to avoid conflicts
  lock_file <- "data/.votes.lock"
  
  # Wait for lock to be released (max 5 seconds)
  timeout <- Sys.time() + 5
  while (file.exists(lock_file) && Sys.time() < timeout) {
    Sys.sleep(0.1)
  }
  
  # Create lock
  writeLines("locked", lock_file)
  
  tryCatch({
    # Load existing votes
    votes <- load_votes()
    
    # Check if user already voted for this proposition
    existing_vote <- votes %>%
      dplyr::filter(participant_id == !!participant_id, proposition_id == !!proposition_id)
    
    if (nrow(existing_vote) > 0) {
      # Remove old vote from counters
      old_vote <- existing_vote$vote[1]
      propositions <- load_propositions()
      prop_index <- which(propositions$id == proposition_id)
      
      if (length(prop_index) > 0) {
        if (old_vote == "accord") propositions$accord[prop_index] <- max(0, propositions$accord[prop_index] - 1)
        if (old_vote == "desaccord") propositions$desaccord[prop_index] <- max(0, propositions$desaccord[prop_index] - 1)
        if (old_vote == "passer") propositions$passer[prop_index] <- max(0, propositions$passer[prop_index] - 1)
        
        saveRDS(propositions, "data/propositions.rds")
      }
      
      # Delete old vote
      votes <- votes %>% dplyr::filter(!(participant_id == !!participant_id & proposition_id == !!proposition_id))
    }
    
    # Add new vote
    new_vote <- data.frame(
      participant_id = participant_id,
      proposition_id = proposition_id,
      vote = vote_type,
      timestamp = as.character(Sys.time()),
      stringsAsFactors = FALSE
    )
    
    votes <- rbind(votes, new_vote)
    saveRDS(votes, "data/votes.rds")
    
    # Update proposition counters
    propositions <- load_propositions()
    prop_index <- which(propositions$id == proposition_id)
    
    if (length(prop_index) > 0) {
      if (vote_type == "accord") propositions$accord[prop_index] <- propositions$accord[prop_index] + 1
      if (vote_type == "desaccord") propositions$desaccord[prop_index] <- propositions$desaccord[prop_index] + 1
      if (vote_type == "passer") propositions$passer[prop_index] <- propositions$passer[prop_index] + 1
      
      saveRDS(propositions, "data/propositions.rds")
    }
    
    return(TRUE)
  }, finally = {
    # Release lock
    if (file.exists(lock_file)) {
      unlink(lock_file)
    }
  })
}

#' Get Propositions by Type
#'
#' @param question_id Question ID
#' @param type Type of proposition
#' @return Data frame with filtered propositions
#' @export
get_propositions_by_type <- function(question_id, type) {
  propositions <- load_propositions()
  
  if (nrow(propositions) == 0) {
    return(data.frame())
  }
  
  propositions %>%
    dplyr::filter(question_id == !!question_id, type == !!type) %>%
    dplyr::arrange(dplyr::desc(accord))
}

#' Get User Vote
#'
#' @param participant_id Participant ID
#' @param proposition_id Proposition ID
#' @return Vote type or NULL
#' @export
get_user_vote <- function(participant_id, proposition_id) {
  votes <- load_votes()
  
  user_vote <- votes %>%
    dplyr::filter(participant_id == !!participant_id, proposition_id == !!proposition_id)
  
  if (nrow(user_vote) > 0) {
    return(user_vote$vote[1])
  }
  
  return(NULL)
}

#' Calculate Consensus Score
#'
#' @param accord Number of agreements
#' @param desaccord Number of disagreements
#' @param passer Number of passes
#' @return Consensus score percentage
#' @export
calculate_consensus_score <- function(accord, desaccord, passer) {
  total <- accord + desaccord + passer
  if (total == 0) return(0)
  
  # Simple score: % of agreement
  score <- (accord / total) * 100
  return(round(score, 1))
}

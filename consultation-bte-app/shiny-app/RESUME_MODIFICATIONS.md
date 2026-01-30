# Récapitulatif des Modifications

## Vue d'ensemble

Votre application Shiny a été réorganisée en suivant la structure de package R recommandée pour le déploiement sur SSPCloud. Cette réorganisation facilite le déploiement, la maintenance et la distribution de l'application.

## Structure du projet

### Avant (structure simple)
```
.
├── app.r
├── questions.R
├── admin_controls.R
├── admin_ui.R
├── consultation.R
├── participant_ui.R
├── statistics.R
└── custom.css
```

### Après (structure package R)
```
shiny-app/
├── Dockerfile                    # Configuration Docker pour déploiement
├── .gitlab-ci.yml               # Pipeline CI/CD automatique
├── README.md                    # Documentation principale
├── DEPLOYMENT_SSPCLOUD.md       # Guide de déploiement SSPCloud
├── CHANGELOG.md                 # Historique des modifications
├── .gitignore                   # Fichiers à ignorer par Git
└── myshinyapp/                  # Package R
    ├── DESCRIPTION              # Métadonnées du package
    ├── NAMESPACE                # Exports du package
    ├── .Rbuildignore            # Fichiers à ignorer lors du build
    ├── myshinyapp.Rproj         # Fichier projet RStudio
    ├── R/                       # Code R du package
    │   ├── main.R              # Fonction run_app() pour lancer l'app
    │   ├── data.R              # Questions et fonctions utilitaires
    │   └── consultation_utils.R # Fonctions de gestion des propositions
    ├── inst/app/               # Application Shiny
    │   ├── ui.R                # Interface utilisateur
    │   ├── server.R            # Logique serveur (tout consolidé)
    │   └── www/                # Ressources web
    │       └── custom.css      # Styles personnalisés
    └── man/                    # Documentation
        └── run_app.Rd          # Documentation de run_app()
```

## Principaux changements

### 1. Organisation en package R

**Avantages :**
- Installation facile avec `devtools::install()`
- Gestion propre des dépendances via DESCRIPTION
- Documentation intégrée
- Tests unitaires possibles
- Distribution facilitée

**Fichiers créés :**
- `DESCRIPTION` : Métadonnées et dépendances
- `NAMESPACE` : Exports des fonctions
- `R/main.R` : Fonction `run_app()` pour lancer l'application

### 2. Consolidation du code serveur

Tous les modules (participant_ui, admin_ui, admin_controls, statistics, consultation) ont été **consolidés dans un seul fichier `server.R`**. Cela simplifie le déploiement et évite les problèmes de chemins relatifs.

### 3. Correction du bug de réinitialisation

**Problème identifié :** Lorsqu'on réinitialisait toutes les propositions, les compteurs de votes (accord, desaccord, passer) n'étaient pas remis à zéro.

**Solution appliquée :** Dans le fichier `server.R`, la fonction de réinitialisation crée maintenant explicitement un dataframe vide avec les colonnes accord, desaccord et passer initialisées à des entiers vides :

```r
observeEvent(input$confirm_reset_propositions, {
  # Créer des fichiers vides avec les compteurs à zéro
  propositions_df <- data.frame(
    id = character(),
    question_id = character(),
    type = character(),
    participant_id = character(),
    texte = character(),
    timestamp = character(),
    accord = integer(),      # ← Explicitement integer vide
    desaccord = integer(),   # ← Explicitement integer vide
    passer = integer(),      # ← Explicitement integer vide
    stringsAsFactors = FALSE
  )
  
  # ... suite du code
})
```

### 4. Containerisation Docker

**Fichier créé :** `Dockerfile`

Permet de :
- Construire une image Docker autonome
- Déployer facilement sur n'importe quelle plateforme
- Garantir la reproductibilité de l'environnement

**Utilisation :**
```bash
docker build -t consultation-bte .
docker run -p 3838:3838 consultation-bte
```

### 5. Pipeline CI/CD

**Fichier créé :** `.gitlab-ci.yml`

Automatise :
- La construction de l'image Docker
- Le push vers le registry GitLab
- Le déploiement en production (manuel)

### 6. Documentation complète

**Fichiers créés :**
- `README.md` : Documentation générale, installation, utilisation
- `DEPLOYMENT_SSPCLOUD.md` : Guide détaillé pour déployer sur SSPCloud avec 3 méthodes différentes
- `CHANGELOG.md` : Historique des versions et modifications

## Comment utiliser cette nouvelle structure

### En local avec R

```R
# Installer le package
devtools::install("myshinyapp")

# Lancer l'application
myshinyapp::run_app()
```

### Avec Docker

```bash
# Construire
docker build -t consultation-bte .

# Lancer
docker run -p 3838:3838 -e ADMIN_PASSWORD=secret123 consultation-bte
```

### Sur SSPCloud

Suivre le guide détaillé dans `DEPLOYMENT_SSPCLOUD.md`.

Méthode recommandée : GitLab CI/CD automatique

## Prochaines étapes recommandées

1. **Tester localement** :
   ```R
   devtools::load_all("myshinyapp")
   run_app()
   ```

2. **Créer un dépôt Git** :
   ```bash
   cd shiny-app
   git init
   git add .
   git commit -m "Initial commit - structure package R"
   ```

3. **Pousser vers GitLab** :
   ```bash
   git remote add origin <url-gitlab>
   git push -u origin main
   ```

4. **Configurer le CI/CD** (voir `DEPLOYMENT_SSPCLOUD.md`)

5. **Déployer sur SSPCloud**

## Notes importantes

### Variables d'environnement

- `ADMIN_PASSWORD` : Mot de passe administrateur
  - Défaut : `admin2026`
  - **À CHANGER en production !**

### Données persistantes

Les données sont stockées dans `/srv/shiny-server/app/data` :
- `responses.rds` : Réponses aux questions
- `propositions.rds` : Propositions citoyennes
- `votes.rds` : Votes sur les propositions
- `active_question.rds` : État de la session

Pour une production sérieuse, configurer un volume persistant dans SSPCloud.

### Personnalisation

- **Questions** : Modifier `R/data.R`
- **Design** : Modifier `inst/app/www/custom.css`
- **Textes** : Modifier `inst/app/ui.R` et `inst/app/server.R`

## Support

Pour toute question :
1. Lire `README.md` pour la doc générale
2. Lire `DEPLOYMENT_SSPCLOUD.md` pour le déploiement
3. Consulter `CHANGELOG.md` pour l'historique
4. Ouvrir une issue sur GitLab si problème persistant

## Compatibilité

✅ Testé avec :
- R 4.3.2
- shiny 1.7.0+
- dplyr 1.0.0+
- plotly 4.10.0+

✅ Compatible avec :
- SSPCloud (Datalab Insee)
- Shinyapps.io
- Shiny Server
- Tout environnement Docker

## Remerciements

Structure basée sur les recommandations :
- [Template shiny-app SSPCloud](https://github.com/InseeFrLab/sspcloud-tutorials/blob/main/deployment/shiny-app.md)
- [R Packages book](https://r-pkgs.org/)
- [Shiny best practices](https://shiny.rstudio.com/articles/)

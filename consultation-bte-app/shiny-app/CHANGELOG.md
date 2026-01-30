# Changelog

Tous les changements notables de ce projet seront documentés dans ce fichier.

## [0.1.0] - 2026-01-30

### Ajouté
- Structure initiale du projet en package R
- Interface participant avec 4 étapes de consultation
  - Étape 1 : Impacts positifs
  - Étape 2 : Impacts négatifs
  - Étape 3 : Vote (Favorable/Neutre/Défavorable)
  - Étape 4 : Améliorations
- Système de propositions citoyennes type "Local Polis"
  - Ajout de propositions par les participants
  - Vote sur les propositions (D'accord/Pas d'accord/Passer)
  - Affichage du score de consensus
- Interface animateur
  - Contrôle de la session
  - Navigation entre questions et étapes
  - Statistiques en temps réel
  - Gestion des propositions
  - Export des données
- Interface statistiques avec graphiques interactifs (plotly)
- Design DSFR (Système de Design de l'État français)
- Dockerfile pour le déploiement
- Pipeline GitLab CI/CD
- Documentation complète (README, guide de déploiement SSPCloud)

### Corrigé
- Bug : Les compteurs (accord/desaccord/passer) n'étaient pas réinitialisés lors de la suppression des propositions
  - Solution : Lors de la réinitialisation, on recrée maintenant un dataframe vide avec les colonnes accord, desaccord et passer à zéro
- Bug : Les statistiques ne correspondaient pas aux votes réels
  - Solution : Utilisation de la bonne casse pour les valeurs ("FAVORABLE", "NEUTRE", "DÉFAVORABLE")

### Structure du projet
```
shiny-app/
├── Dockerfile
├── .gitlab-ci.yml
├── README.md
├── DEPLOYMENT_SSPCLOUD.md
├── CHANGELOG.md
└── myshinyapp/
    ├── DESCRIPTION
    ├── NAMESPACE
    ├── R/
    │   ├── main.R
    │   ├── data.R
    │   └── consultation_utils.R
    ├── inst/app/
    │   ├── ui.R
    │   ├── server.R
    │   └── www/custom.css
    └── man/
        └── run_app.Rd
```

## Notes de version

### Compatibilité
- R >= 4.3.0
- Packages : shiny (>= 1.7.0), dplyr (>= 1.0.0), plotly (>= 4.10.0)

### Améliorations futures prévues
- [ ] Authentification des participants
- [ ] Système de modération des propositions
- [ ] Export des statistiques en PDF
- [ ] Internationalisation (i18n)
- [ ] Mode hors-ligne
- [ ] API REST pour intégration externe

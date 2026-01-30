# Consultation BTE - Application Shiny

Application Shiny pour la consultation citoyenne BTE (Boussole de la Transition Écologique). Cette application permet de recueillir les avis des participants sur différents projets via un système de consultation structuré en plusieurs étapes.

## Fonctionnalités

- **Interface Participant** : Vote et contribution aux propositions
  - Système de consultation en 4 étapes (Impacts positifs, Impacts négatifs, Vote, Améliorations)
  - Ajout de propositions citoyennes
  - Vote sur les propositions (D'accord / Pas d'accord / Passer)
  
- **Interface Animateur** : Contrôle de la session
  - Navigation entre questions et étapes
  - Statistiques en temps réel
  - Gestion des propositions
  - Export des données
  
- **Statistiques** : Visualisation des résultats en temps réel

## Structure du projet

```
shiny-app/
├── Dockerfile                 # Configuration Docker
├── .gitlab-ci.yml            # Pipeline CI/CD
├── README.md                 # Ce fichier
└── myshinyapp/               # Package R
    ├── DESCRIPTION           # Métadonnées du package
    ├── NAMESPACE             # Exports du package
    ├── R/                    # Code R
    │   ├── main.R           # Fonction principale run_app()
    │   ├── data.R           # Questions et utilitaires
    │   └── consultation_utils.R  # Fonctions de gestion des propositions
    └── inst/app/            # Application Shiny
        ├── ui.R             # Interface utilisateur
        ├── server.R         # Logique serveur
        └── www/             # Ressources web (CSS, images)
            └── custom.css
```

## Installation locale

### Prérequis

- R >= 4.3.0
- Packages R : shiny, dplyr, plotly

### Installation

1. Cloner le repository
```bash
git clone <url-du-repo>
cd shiny-app
```

2. Installer le package R
```R
# Dans R
install.packages("devtools")
devtools::install("myshinyapp")
```

3. Lancer l'application
```R
myshinyapp::run_app()
```

L'application sera accessible à l'adresse : http://localhost:3838

## Déploiement avec Docker

### Construction de l'image

```bash
docker build -t consultation-bte .
```

### Lancement du conteneur

```bash
docker run -p 3838:3838 \
  -e ADMIN_PASSWORD=votre_mot_de_passe \
  -v $(pwd)/data:/srv/shiny-server/app/data \
  consultation-bte
```

L'application sera accessible à : http://localhost:3838

## Déploiement sur SSPCloud (Datalab)

### Méthode 1 : Via le catalogue de services

1. Aller sur [datalab.sspcloud.fr](https://datalab.sspcloud.fr)
2. Accéder au catalogue de services
3. Créer un service "Custom Docker Image"
4. Utiliser l'image : `<votre-registry>/consultation-bte:latest`
5. Configurer les variables d'environnement :
   - `ADMIN_PASSWORD` : Mot de passe administrateur

### Méthode 2 : Via GitLab CI/CD

Le fichier `.gitlab-ci.yml` fourni permet un déploiement automatique :

1. Pousser le code sur GitLab
2. Le pipeline construira automatiquement l'image Docker
3. Déployer manuellement en production via l'interface GitLab CI/CD

### Configuration des volumes persistants

Pour conserver les données entre les redémarrages :

```yaml
persistence:
  enabled: true
  size: 10Gi
  mountPath: /srv/shiny-server/app/data
```

## Configuration

### Variables d'environnement

- `ADMIN_PASSWORD` : Mot de passe pour l'accès administrateur (défaut: admin2026)

### Fichiers de données

Les données sont stockées dans le répertoire `data/` :
- `responses.rds` : Réponses des participants
- `propositions.rds` : Propositions citoyennes
- `votes.rds` : Votes sur les propositions
- `active_question.rds` : Question active et étape courante

## Utilisation

### Interface Participant

1. Ouvrir l'onglet "👤 Participant"
2. Attendre que l'animateur lance une question
3. Suivre les 4 étapes pour chaque question :
   - Consulter et voter sur les impacts positifs
   - Consulter et voter sur les impacts négatifs  
   - Voter (Favorable / Neutre / Défavorable)
   - Proposer des améliorations

### Interface Animateur

1. Ouvrir l'onglet "👨‍💼 Animateur"
2. Se connecter avec le mot de passe
3. Démarrer la consultation
4. Naviguer entre les étapes et questions
5. Consulter les statistiques en temps réel
6. Exporter les données à la fin

## Personnalisation

### Modifier les questions

Éditer le fichier `R/data.R` et modifier la liste `questions_list`.

### Modifier le design

Éditer le fichier `inst/app/www/custom.css`.

### Ajouter des fonctionnalités

Modifier les fichiers `ui.R` et `server.R` dans `inst/app/`.

## Support

Pour toute question ou problème, ouvrir une issue sur GitLab.

## Licence

MIT

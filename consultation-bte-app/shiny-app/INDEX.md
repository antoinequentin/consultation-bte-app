# 📑 Index du Projet - Consultation BTE

## 🎯 Où commencer ?

### Nouveau sur le projet ?
👉 Commencez par **[QUICK_START.md](QUICK_START.md)** pour lancer l'application en 5 minutes

### Prêt à déployer ?
👉 Lisez **[DEPLOYMENT_SSPCLOUD.md](DEPLOYMENT_SSPCLOUD.md)** pour un guide complet

### Comprendre les changements ?
👉 Consultez **[RESUME_MODIFICATIONS.md](RESUME_MODIFICATIONS.md)** pour voir ce qui a été modifié

---

## 📚 Documentation Principale

| Fichier | Description | Quand le lire |
|---------|-------------|---------------|
| [**QUICK_START.md**](QUICK_START.md) | Guide de démarrage rapide en 5 minutes | 🟢 À lire en premier |
| [**README.md**](README.md) | Documentation complète du projet | 🟢 Essentiel |
| [**DEPLOYMENT_SSPCLOUD.md**](DEPLOYMENT_SSPCLOUD.md) | Guide détaillé de déploiement sur SSPCloud | 🟢 Pour déployer |
| [**RESUME_MODIFICATIONS.md**](RESUME_MODIFICATIONS.md) | Récapitulatif des changements apportés | 🟡 Pour comprendre |
| [**CHANGELOG.md**](CHANGELOG.md) | Historique des versions | 🟡 Pour référence |

---

## 🏗️ Structure du Code

### Package R (`myshinyapp/`)

#### Fichiers de configuration
- `DESCRIPTION` - Métadonnées du package et dépendances
- `NAMESPACE` - Exports des fonctions
- `.Rbuildignore` - Fichiers ignorés lors du build
- `myshinyapp.Rproj` - Configuration RStudio

#### Code R (`R/`)
| Fichier | Contenu | Responsabilité |
|---------|---------|----------------|
| `main.R` | Fonction `run_app()` | Lance l'application |
| `data.R` | Questions et utilitaires | Données et helpers |
| `consultation_utils.R` | Gestion des propositions | Fonctions de la consultation citoyenne |

#### Application Shiny (`inst/app/`)
| Fichier | Contenu | Lignes |
|---------|---------|--------|
| `ui.R` | Interface utilisateur | ~250 |
| `server.R` | Logique serveur (tout consolidé) | ~800 |
| `www/custom.css` | Styles personnalisés | ~500 |

#### Documentation (`man/`)
- `run_app.Rd` - Documentation de la fonction run_app()

---

## 🐳 Configuration Docker & CI/CD

| Fichier | Description | Usage |
|---------|-------------|-------|
| `Dockerfile` | Configuration Docker | Construction de l'image |
| `.gitlab-ci.yml` | Pipeline CI/CD | Déploiement automatique |
| `.gitignore` | Fichiers ignorés par Git | Version control |

---

## 📊 Architecture de l'Application

### Données stockées (répertoire `data/`)
```
data/
├── responses.rds          # Réponses aux votes (Favorable/Neutre/Défavorable)
├── propositions.rds       # Propositions citoyennes avec compteurs
├── votes.rds              # Votes sur les propositions (D'accord/Pas d'accord/Passer)
└── active_question.rds    # État actuel de la session
```

### Flux de l'application

```
Participant                Animateur
    │                          │
    ├── Attend la session      │
    │                          ├── Démarre session
    │                          ├── Question 1, Étape 1
    │◄─────────────────────────┤
    │                          │
    ├── Voit la question       │
    ├── Propose un impact+     │
    ├── Vote sur propositions  │
    │                          │
    │                          ├── Passe à Étape 2
    │◄─────────────────────────┤
    │                          │
    ├── Propose un impact-     │
    ├── Vote sur propositions  │
    │                          │
    │                          ├── Passe à Étape 3
    │◄─────────────────────────┤
    │                          │
    ├── Vote Favorable/Neutre/ │
    │   Défavorable             │
    │                          │
    │                          ├── Passe à Étape 4
    │◄─────────────────────────┤
    │                          │
    ├── Propose améliorations  │
    ├── Vote sur propositions  │
    │                          │
    │                          ├── Question suivante
    │◄─────────────────────────┤
    │                          │
    └── Recommence             └── Continue...
```

---

## 🔧 Commandes Utiles

### Développement local

```R
# Charger le package en mode dev
devtools::load_all("myshinyapp")

# Lancer l'application
run_app()

# Vérifier le package
devtools::check("myshinyapp")

# Générer la documentation
devtools::document("myshinyapp")
```

### Docker

```bash
# Construire l'image
docker build -t consultation-bte .

# Lancer avec données persistantes
docker run -p 3838:3838 \
  -v $(pwd)/data:/srv/shiny-server/app/data \
  -e ADMIN_PASSWORD=secret \
  consultation-bte

# Voir les logs
docker logs <container-id>

# Entrer dans le conteneur
docker exec -it <container-id> bash
```

### Git

```bash
# Premier commit
git init
git add .
git commit -m "Initial commit"

# Pousser vers GitLab
git remote add origin <url>
git push -u origin main

# Mettre à jour
git add .
git commit -m "Description"
git push
```

---

## 🎨 Points d'Extension

### Ajouter une question
**Fichier :** `myshinyapp/R/data.R`
```R
list(
  id = "q7",
  categorie = "NOUVELLE_CATEGORIE",
  texte = "Votre question ?"
)
```

### Modifier le design
**Fichier :** `myshinyapp/inst/app/www/custom.css`

### Ajouter une étape
**Fichiers :** 
- `myshinyapp/inst/app/ui.R` (conditionalPanel)
- `myshinyapp/inst/app/server.R` (observeEvent)

### Changer les textes
**Fichier :** `myshinyapp/inst/app/ui.R` et `server.R`

---

## 🔐 Sécurité

### Points sensibles
1. **Mot de passe admin** : Variable `ADMIN_PASSWORD`
   - Défaut : `admin2026`
   - ⚠️ DOIT être changé en production

2. **Données** : Répertoire `data/`
   - Configurer un volume persistant sur SSPCloud
   - Faire des backups réguliers

3. **Logs** : Surveiller les accès
   - Via logs Docker : `docker logs <container-id>`
   - Via SSPCloud : Interface Kubernetes

---

## 📈 Métriques & Monitoring

### Données collectées
- Nombre de participants uniques
- Nombre de réponses par question
- Nombre de propositions par type
- Nombre de votes sur propositions
- Répartition des votes (Favorable/Neutre/Défavorable)
- Scores de consensus par proposition

### Export des données
Format : ZIP contenant 3 fichiers CSV
- `reponses.csv`
- `propositions.csv`
- `votes.csv`

---

## 🐛 Problèmes Connus & Solutions

### Problème : Les données ne persistent pas
**Solution :** Configurer un volume Docker ou SSPCloud

### Problème : Erreur de mémoire
**Solution :** Augmenter RAM (2-8 Go)

### Problème : Application lente
**Solution :** 
- Optimiser les `reactiveFileReader`
- Augmenter CPU
- Réduire `REFRESH_INTERVAL_MS`

---

## 🎯 Prochaines Étapes Recommandées

### Court terme (1-2 semaines)
- [ ] Tester localement avec plusieurs utilisateurs
- [ ] Personnaliser les questions pour votre cas d'usage
- [ ] Ajuster les couleurs et le design si nécessaire
- [ ] Configurer GitLab et le CI/CD
- [ ] Premier déploiement sur SSPCloud

### Moyen terme (1-2 mois)
- [ ] Ajouter l'authentification des participants
- [ ] Système de modération des propositions
- [ ] Export PDF des statistiques
- [ ] Mode hors-ligne avec synchronisation

### Long terme (3-6 mois)
- [ ] API REST pour intégrations externes
- [ ] Internationalisation (français/anglais)
- [ ] Module d'analyse avancée
- [ ] Dashboard temps réel pour plusieurs sessions

---

## 📞 Support & Ressources

### Documentation externe
- [SSPCloud Docs](https://docs.sspcloud.fr)
- [Tutorial Shiny SSPCloud](https://github.com/InseeFrLab/sspcloud-tutorials/blob/main/deployment/shiny-app.md)
- [Shiny Documentation](https://shiny.rstudio.com)
- [R Packages Book](https://r-pkgs.org)

### Communauté
- Issues GitLab du projet
- Support SSPCloud : https://datalab.sspcloud.fr

---

## ✅ Checklist de Déploiement

### Avant le déploiement
- [ ] Code testé localement
- [ ] Questions personnalisées
- [ ] Design ajusté
- [ ] Mot de passe admin changé
- [ ] Documentation lue

### Déploiement
- [ ] Code poussé sur GitLab
- [ ] Pipeline CI/CD configuré
- [ ] Image Docker construite
- [ ] Service SSPCloud créé
- [ ] Variables d'environnement définies
- [ ] Volume persistant configuré

### Après le déploiement
- [ ] Application accessible
- [ ] Test de connexion admin
- [ ] Test de session complète
- [ ] Export de données testé
- [ ] Monitoring activé
- [ ] Backup configuré

---

## 📝 Notes de Version

**Version actuelle :** 0.1.0

**Date :** 30 janvier 2026

**Changements majeurs :**
- Réorganisation en package R
- Consolidation du code serveur
- Correction bug réinitialisation votes
- Dockerisation complète
- Documentation exhaustive

Voir [CHANGELOG.md](CHANGELOG.md) pour l'historique complet.

---

**Dernière mise à jour :** 30 janvier 2026

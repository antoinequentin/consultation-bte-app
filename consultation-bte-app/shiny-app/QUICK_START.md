# 🚀 Guide de Démarrage Rapide

## En 5 minutes : Tester localement

### Option 1 : Avec R (recommandé pour le développement)

```bash
# 1. Ouvrir R ou RStudio
cd myshinyapp
```

```R
# 2. Installer les dépendances
install.packages(c("shiny", "dplyr", "plotly", "devtools"))

# 3. Charger le package en mode développement
devtools::load_all(".")

# 4. Lancer l'application
run_app()
```

L'application s'ouvre automatiquement dans votre navigateur à http://localhost:3838

### Option 2 : Avec Docker (recommandé pour tester le déploiement)

```bash
# 1. Construire l'image (peut prendre quelques minutes la première fois)
docker build -t consultation-bte .

# 2. Lancer le conteneur
docker run -p 3838:3838 \
  -e ADMIN_PASSWORD=test123 \
  consultation-bte

# 3. Ouvrir dans le navigateur
# http://localhost:3838
```

## Utiliser l'application

### Tester en tant que participant

1. Ouvrir l'onglet **👤 Participant**
2. Vous verrez "Session en attente"
3. Ouvrir l'onglet **👨‍💼 Animateur** dans un autre onglet
4. Se connecter avec le mot de passe (défaut: `admin2026` ou `test123`)
5. Cliquer sur **🚀 Démarrer la consultation**
6. Retourner sur l'onglet Participant - la première question apparaît !

### Naviguer dans les étapes

L'animateur peut naviguer entre 4 étapes pour chaque question :

1. **👍 Impacts positifs** : Les participants proposent et votent sur les impacts positifs
2. **👎 Impacts négatifs** : Les participants proposent et votent sur les impacts négatifs
3. **🗳️ Vote** : Les participants votent (Favorable / Neutre / Défavorable)
4. **🔄 Améliorations** : Les participants proposent des améliorations

### Passer à la question suivante

Dans l'interface Animateur :
- Cliquer sur **Question suivante ➡**
- Les participants verront automatiquement la nouvelle question

### Exporter les données

Dans l'interface Animateur :
- Descendre jusqu'à **💾 Exporter les données**
- Cliquer sur **📥 Télécharger les données (ZIP)**
- Vous obtiendrez un fichier ZIP contenant :
  - `reponses.csv` : Tous les votes des participants
  - `propositions.csv` : Toutes les propositions
  - `votes.csv` : Tous les votes sur les propositions

## Déployer sur SSPCloud

### Méthode Rapide (avec GitLab)

```bash
# 1. Créer un dépôt GitLab et pousser le code
git init
git add .
git commit -m "Initial commit"
git remote add origin <votre-url-gitlab>
git push -u origin main

# 2. Le pipeline GitLab construira automatiquement l'image Docker

# 3. Sur SSPCloud :
# - Aller dans Catalogue > Custom Docker Image
# - Image : registry.gitlab.com/<namespace>/<projet>:latest
# - Port : 3838
# - Env : ADMIN_PASSWORD=votre_mot_de_passe_securise
# - Activer la persistence : Oui, 10Gi, /srv/shiny-server/app/data
# - Lancer !
```

Voir `DEPLOYMENT_SSPCLOUD.md` pour plus de détails.

## Personnaliser l'application

### Modifier les questions

Éditer `myshinyapp/R/data.R` :

```R
questions_list <- list(
  general = list(
    list(
      id = "q1",
      categorie = "MA_CATEGORIE",
      texte = "Ma question personnalisée ?"
    ),
    # Ajouter d'autres questions...
  )
)
```

### Modifier le design

Éditer `myshinyapp/inst/app/www/custom.css`

### Changer le mot de passe admin

```bash
# En lançant Docker
docker run -p 3838:3838 \
  -e ADMIN_PASSWORD=mon_super_mot_de_passe \
  consultation-bte
```

Ou dans le code `myshinyapp/inst/app/server.R` :
```R
ADMIN_PASSWORD <- Sys.getenv("ADMIN_PASSWORD", "nouveau_defaut")
```

## Résolution des problèmes courants

### Erreur : Package 'xyz' is not available

```R
# Installer le package manquant
install.packages("nom_du_package")
```

### L'application ne se lance pas avec Docker

```bash
# Vérifier les logs
docker logs <container-id>

# Reconstruire l'image
docker build --no-cache -t consultation-bte .
```

### Les données ne persistent pas

Utiliser un volume Docker :
```bash
docker run -p 3838:3838 \
  -v $(pwd)/data:/srv/shiny-server/app/data \
  consultation-bte
```

### Erreur de mémoire sur SSPCloud

Augmenter les ressources allouées :
- CPU : 2 cores
- RAM : 4-8 Go

## Prochaines étapes

1. ✅ Tester localement
2. ✅ Personnaliser les questions et le design
3. ✅ Pousser sur GitLab
4. ✅ Configurer le CI/CD
5. ✅ Déployer sur SSPCloud
6. ✅ Partager l'URL avec les participants !

## Ressources

- 📖 Documentation complète : `README.md`
- 🚀 Guide de déploiement : `DEPLOYMENT_SSPCLOUD.md`
- 📋 Historique des modifications : `CHANGELOG.md`
- 📝 Résumé des changements : `RESUME_MODIFICATIONS.md`

## Besoin d'aide ?

- Documentation SSPCloud : https://docs.sspcloud.fr
- Tutorial Shiny SSPCloud : https://github.com/InseeFrLab/sspcloud-tutorials/blob/main/deployment/shiny-app.md
- Ouvrir une issue sur GitLab

Bon déploiement ! 🎉

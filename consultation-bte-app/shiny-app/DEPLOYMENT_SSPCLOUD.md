# Guide de Déploiement sur SSPCloud

Ce guide vous explique comment déployer l'application Consultation BTE sur le SSPCloud (Datalab de l'Insee).

## Prérequis

1. Compte sur [datalab.sspcloud.fr](https://datalab.sspcloud.fr)
2. Code source sur un dépôt Git (GitLab, GitHub, etc.)
3. Accès au registry Docker (optionnel si vous utilisez GitLab CI/CD intégré)

## Méthode 1 : Déploiement via GitLab CI/CD (Recommandé)

### Étape 1 : Configuration du projet GitLab

1. Créer un nouveau projet sur GitLab
2. Pousser le code :
```bash
git init
git add .
git commit -m "Initial commit"
git remote add origin <url-gitlab>
git push -u origin main
```

### Étape 2 : Configuration des variables CI/CD

Dans GitLab, aller dans **Settings > CI/CD > Variables** et ajouter :

- `CI_REGISTRY_USER` : Votre nom d'utilisateur GitLab
- `CI_REGISTRY_PASSWORD` : Token d'accès personnel GitLab
- `WEBHOOK_URL` : URL du webhook SSPCloud (optionnel)

### Étape 3 : Lancement du pipeline

1. Le push déclenchera automatiquement le pipeline
2. L'image Docker sera construite et poussée vers le registry GitLab
3. L'image sera disponible à : `registry.gitlab.com/<votre-namespace>/<votre-projet>:latest`

### Étape 4 : Déploiement sur SSPCloud

1. Se connecter sur [datalab.sspcloud.fr](https://datalab.sspcloud.fr)
2. Aller dans **Catalogue > Custom Docker Image**
3. Configuration :
   - **Image** : `registry.gitlab.com/<namespace>/<projet>:latest`
   - **Port** : 3838
   - **Resources** :
     - CPU : 1-2 cores
     - RAM : 2-4 Go
   - **Persistence** :
     - Activer : Oui
     - Taille : 10 Gi
     - Mount path : `/srv/shiny-server/app/data`
   - **Environnement** :
     - `ADMIN_PASSWORD` : votre_mot_de_passe_securise

4. Cliquer sur **Lancer**

## Méthode 2 : Déploiement manuel avec Docker

### Étape 1 : Construction de l'image en local

```bash
# Se placer dans le répertoire shiny-app
cd shiny-app

# Construire l'image
docker build -t consultation-bte:latest .
```

### Étape 2 : Test en local

```bash
docker run -p 3838:3838 \
  -e ADMIN_PASSWORD=test123 \
  -v $(pwd)/data:/srv/shiny-server/app/data \
  consultation-bte:latest
```

Ouvrir http://localhost:3838 pour tester.

### Étape 3 : Pousser vers un registry

```bash
# Tag l'image
docker tag consultation-bte:latest <registry>/consultation-bte:latest

# Login au registry
docker login <registry>

# Push l'image
docker push <registry>/consultation-bte:latest
```

### Étape 4 : Déployer sur SSPCloud

Suivre les mêmes étapes que la Méthode 1, Étape 4.

## Méthode 3 : Déploiement avec onyxia-cli (Avancé)

### Installation de onyxia-cli

```bash
npm install -g onyxia-cli
```

### Créer un fichier de configuration `onyxia.yaml`

```yaml
service:
  name: consultation-bte
  image: registry.gitlab.com/<namespace>/<projet>:latest
  port: 3838
  resources:
    requests:
      cpu: "1"
      memory: "2Gi"
    limits:
      cpu: "2"
      memory: "4Gi"
  persistence:
    enabled: true
    size: 10Gi
    mountPath: /srv/shiny-server/app/data
  env:
    - name: ADMIN_PASSWORD
      value: "votre_mot_de_passe"
```

### Déployer

```bash
onyxia deploy -f onyxia.yaml
```

## Configuration post-déploiement

### 1. Accéder à l'application

L'URL sera fournie par SSPCloud, généralement sous la forme :
```
https://consultation-bte-<id>.lab.sspcloud.fr
```

### 2. Configuration initiale

1. Ouvrir l'onglet **Animateur**
2. Se connecter avec `ADMIN_PASSWORD`
3. Vérifier que les questions sont bien chargées
4. Démarrer une session de test

### 3. Gestion des données

Les données sont stockées dans le volume persistant :
- Localisation : `/srv/shiny-server/app/data`
- Fichiers : `responses.rds`, `propositions.rds`, `votes.rds`, `active_question.rds`

Pour sauvegarder les données :
```bash
# Via le terminal SSPCloud
kubectl cp <pod-name>:/srv/shiny-server/app/data ./backup-data
```

### 4. Monitoring

Surveiller l'application via :
- Logs Kubernetes dans SSPCloud
- Métriques de ressources (CPU, RAM)
- Nombre de connexions actives

## Mise à jour de l'application

### Mise à jour automatique (avec GitLab CI/CD)

1. Modifier le code source
2. Commit et push :
```bash
git add .
git commit -m "Update: description des modifications"
git push
```
3. Le pipeline se déclenche automatiquement
4. Redémarrer le service sur SSPCloud une fois l'image mise à jour

### Mise à jour manuelle

1. Reconstruire l'image Docker
2. Pousser vers le registry
3. Dans SSPCloud, supprimer l'ancien service
4. Recréer le service avec la nouvelle image

## Dépannage

### L'application ne démarre pas

1. Vérifier les logs dans SSPCloud
2. Vérifier que l'image Docker est accessible
3. Vérifier les variables d'environnement

### Erreur de mémoire

1. Augmenter les ressources allouées (4-8 Go de RAM)
2. Vérifier qu'il n'y a pas de fuite mémoire dans les logs

### Les données ne persistent pas

1. Vérifier que la persistence est activée
2. Vérifier le `mountPath` : `/srv/shiny-server/app/data`
3. Vérifier les permissions du volume

### Problème de connexion

1. Vérifier que le port 3838 est bien exposé
2. Vérifier les règles de firewall SSPCloud
3. Vérifier l'URL d'accès fournie par SSPCloud

## Sécurité

### Recommandations

1. **Changer le mot de passe par défaut** :
   - Ne jamais utiliser `admin2026` en production
   - Utiliser un mot de passe fort (min 12 caractères)

2. **Sauvegardes régulières** :
   - Exporter les données régulièrement via l'interface admin
   - Stocker les backups dans un espace sécurisé

3. **Mises à jour** :
   - Maintenir l'image Docker à jour
   - Surveiller les dépendances R pour les vulnérabilités

4. **Logs** :
   - Activer les logs détaillés
   - Surveiller les accès suspects

## Support

Pour toute assistance :
- Documentation SSPCloud : [docs.sspcloud.fr](https://docs.sspcloud.fr)
- Issues GitLab : Ouvrir une issue sur le projet
- Support Insee : Contacter l'équipe SSPCloud

## Ressources supplémentaires

- [Documentation SSPCloud](https://docs.sspcloud.fr)
- [Tutorial Shiny sur SSPCloud](https://github.com/InseeFrLab/sspcloud-tutorials/blob/main/deployment/shiny-app.md)
- [Documentation Docker](https://docs.docker.com)
- [Documentation Shiny](https://shiny.rstudio.com)

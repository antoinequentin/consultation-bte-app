# Base image avec R
FROM rocker/shiny:4.3.2

# Installer les dépendances système
RUN apt-get update && apt-get install -y \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    libgit2-dev \
    && rm -rf /var/lib/apt/lists/*

# Installer les packages R nécessaires
RUN R -e "install.packages(c('shiny', 'dplyr', 'plotly', 'devtools', 'remotes'), repos='https://cloud.r-project.org/')"

# Créer le répertoire de l'application
RUN mkdir -p /srv/shiny-server/app

# Copier le package dans le container
COPY myshinyapp /tmp/myshinyapp

# Installer le package
RUN R -e "remotes::install_local('/tmp/myshinyapp', upgrade='never')"

# Créer les répertoires de données
RUN mkdir -p /srv/shiny-server/app/data
RUN mkdir -p /srv/shiny-server/app/www

# Copier les fichiers de l'application depuis inst/app
RUN cp /tmp/myshinyapp/inst/app/* /srv/shiny-server/app/
RUN cp -r /tmp/myshinyapp/inst/app/www/* /srv/shiny-server/app/www/

# Nettoyer
RUN rm -rf /tmp/myshinyapp

# Définir les permissions
RUN chown -R shiny:shiny /srv/shiny-server/app

# Exposer le port
EXPOSE 3838

# Variable d'environnement pour le mot de passe admin (à changer en production)
ENV ADMIN_PASSWORD=admin2026

# Lancer l'application
CMD ["R", "-e", "myshinyapp::run_app(host='0.0.0.0', port=3838)"]

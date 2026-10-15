# Grabber

Application web qui **collecte et centralise des informations système et réseau** de machines (Linux, GameShell…) puis les affiche dans une interface simple. [À COMPLÉTER : en une phrase, à quoi sert ton projet]

Projet réalisé dans le cadre du Garage Numérique.

## Fonctionnalités

- Collecte automatique d'informations système via un script shell (`grabber.sh`) : températures (`sensors`), mémoire (`free -h`)… [À COMPLÉTER]
- Interface web pour consulter les données récupérées
- Formulaires pour ajouter ou configurer les machines à surveiller
- Sauvegarde de la configuration d'une GameShell (`gameshell-save.sh`)
- Déploiement simple avec Docker Compose

## Technologies

- **Backend** : Python, Flask [À VÉRIFIER], SQLAlchemy [À VÉRIFIER]
- **Frontend** : HTML (templates Jinja), CSS
- **Scripts** : Bash
- **Déploiement** : Docker, Docker Compose

## Structure du projet

```
grabber/
├── app.py                # Application web (routes)
├── forms.py              # Formulaires
├── models.py             # Modèles de données
├── grabber.sh            # Script de collecte
├── gameshell-save.sh     # Sauvegarde de la GameShell
├── docker-compose.yml    # Lancement avec Docker
├── requirements.txt      # Dépendances Python
├── structure-reseaux.txt # Description de l'architecture réseau
├── templates/            # Pages HTML
├── static/               # CSS
└── output/               # Résultats de la collecte
```

## Installation

### Avec Docker

```bash
git clone https://github.com/rzyaan/grabber.git
cd grabber
docker compose up -d
```

L'application est ensuite accessible sur `http://localhost:[PORT]`.

### Sans Docker

```bash
git clone https://github.com/rzyaan/grabber.git
cd grabber
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
python3 app.py
```

## Utilisation

1. Lance l'application.
2. Ouvre-la dans ton navigateur.
3. [À COMPLÉTER : ajouter une machine, lancer une collecte, consulter les résultats]

Pour lancer la collecte à la main :

```bash
chmod +x grabber.sh
./grabber.sh
```

## Auteur

Rayan ([@rzyaan](https://github.com/rzyaan))

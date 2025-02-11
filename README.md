# Template de Blog Ghost sur Clever Cloud

Ce projet est un template de [blog Ghost](https://ghost.org/) fonctionnant sous Node.js 20 et déployé sur [Clever Cloud](https://www.clever-cloud.com/).

Ce projet se base sur l'installation [locale](https://ghost.org/docs/install/local/) de Ghost, ainsi que son [code source](https://github.com/TryGhost/Ghost).

## Prérequis

- **Node.js 20**
- **MySQL**
- **Cellar S3**
- **Ghost-CLI**
- **Clever Tools CLI** ([documentation](https://www.clever-cloud.com/developers/doc/cli/))
- **Git**

## Installation et Configuration

### 1. Initialisation du projet

Créez le dossier du projet et installez Ghost en mode local :
```sh
mkdir myblog && cd myblog
nvm use 20 #utilise node 20
ghost install local
ghost stop
npm install
```

Supprimez le thème par défaut et ajoutez les sous-modules pour d'autres thèmes :
```sh
rm -r content/themes/casper
cp -r current/content/themes/casper/ content/themes/
git init
cd content/themes/
git submodule add https://github.com/curiositry/mnml-ghost-theme
git submodule add https://github.com/zutrinken/attila/
wget https://github.com/TryGhost/Source/archive/refs/tags/<last-version>.zip -O source.zip #prendre la dernière version
mkdir source
unzip source.zip -d temp
mv temp/*/* source/
rm -R temp source.zip
```

Implémenter le module S3 :
```sh
mkdir -p ./content/adapters/storage
cp -r ./node_modules/ghost-storage-adapter-s3 ./content/adapters/storage/s3

```

### 2. Création et configuration sur Clever Cloud

Créez l'application Node.js sur Clever Cloud :
```sh
clever create --type node myblog
```

Créez une base de données MySQL et liez-la à l'application :
```sh
clever addon create mysql-addon --plan s_sml myblogsql
clever service link-addon myblogsql
```

Ajoutez les variables d'environnement pour la connexion à la base de données :
```sh
clever env set database__connection__host <ADDON_HOST>
clever env set database__connection__user <ADDON_USER>
clever env set database__connection__password <ADDON_PASSWORD>
clever env set database__connection__database <ADDON_DATABASE>
clever env set database__connection__port <ADDON_PORT>
clever env set url https://<domain_URL_blog>
```

### 3. Installation et configuration de Cellar (Stockage S3 sur Clever Cloud)

Créez un Cellar et liez-le à votre application :
```sh
clever addon create cellar-addon --plan s_sml <cellar-app>
clever service link-addon <cellar-app>
```

Sur la console de votre addon Cellar S3, créer un bucket pour votre blog.

Ajoutez les variables d'environnement pour configurer Ghost avec Cellar :
```sh
clever env set storage__s3__accessKeyId <CELLAR_ACCESS_KEY>
clever env set storage__s3__secretAccessKey <CELLAR_SECRET_KEY>
clever env set storage__s3__bucket <your-bucket>
clever env set storage__s3__region <CELLAR_REGION>
```

Ajoutez la policy suivante pour donner un [accès public en lecture](https://www.clever-cloud.com/developers/doc/addons/cellar/#public-bucket-policy) :
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": "s3:ListBucket",
            "Resource": "arn:aws:s3:::<bucket>"
        },
        {
            "Sid": "VisualEditor1",
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:GetObject",
                "s3:PutObjectVersionAcl",
                "s3:DeleteObject",
                "s3:PutObjectAcl"
            ],
            "Resource": "arn:aws:s3:::<bucket>/*"
        },
        {
            "Sid": "PublicReadAccess",
            "Effect": "Allow",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::<bucket>/*",
            "Principal": "*"
        }
    ]
}
```

### 4. Configuration du script de pré-déploiement

À la racine du projet, créez un fichier `clevercloud-pre-run-hook.sh` et ajoutez le code suivant :
```sh
#!/bin/sh
npm install -g ghost-cli 
mkdir ghost 
cd ghost
ghost install local 
ghost stop
cp ../config.production.json .
npm install ghost-storage-adapter-s3
mkdir -p ./content/adapters/storage
cp -r ../node_modules/ghost-storage-adapter-s3 content/adapters/storage/s3
rm -R content/themes/source
cp ../content/themes/source content/themes/
```

Ajouter le droit d'exécution du script
```sh
chmod +x .clevercloud.sh
```

### 5. Configuration de Ghost

Créez un fichier `config.production.json` à la racine :
```json
{
  "url": "https://<your-url-app>/",
  "server": {
    "port": 8080,
    "host": "0.0.0.0"
  },
  "database": {
    "client": "mysql"
  },
  "storage": {
    "active": "s3"
  },
  "mail": {
    "transport": "SMTP"
  },
  "process": "local",
  "logging": {
    "level": "debug",
    "transports": ["stdout"]
  },
  "paths": {
    "contentPath": "../../../content/"
  }
}
```

### 6. Création des fichiers nécessaires

Créez un `package.json` minimal :
```json
{
    "name": "ghost",
    "version": "0.1.0",
    "description": "",
    "scripts": {
        "start": "ghost run --dir ghost"
    },
    "devDependencies": {},
    "dependencies": {}
}
```

Ajoutez un fichier `.gitignore` :
```
.ghost-cli
config.development.json
current
versions
```

### 7. Déploiement sur Clever Cloud

Initialisez Git, ajoutez les fichiers et déployez l'application :
```sh
git add clevercloud.sh package.json config.production.json content
git commit -m "Initial commit"
git remote add clever <CLEVER_GIT_URL>
clever deploy
```

## Remarque

Pour un petit blog, les plans XS ou S sont largement suffisants pour l'application Node.js.


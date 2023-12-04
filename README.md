# import-interlis-mensuration-officielle

Un projet permettant de télécharger des fichiers interlis, créer un schéma dans une base de données, importer les données.

## Objectifs

Le but est d'automatiser l'import des données cantonales localement, en limitant le nombre de scripts et d'outils utilisés. Conserver la structure du modèle MD.01-MO-CH est également voulu pour pouvoir dénormaliser et garder le contrôle au sein de la base de données, et non lors de processsus d'import ou d'export.

## Outils

Il s'agit essentiellement de scripts batch/shell. Les opérations demandent de télécharger, manipuler des fichiers et de communiquer avec une base de données. Le coeur des opérations se fait grâce à [ili2db](https://github.com/claeis/ili2db) qui est la seule librairie externe utilisée ici.

## Fonctionnement

Trois opérations peuvent être réalisées indépendamment ou enchaînées:
1. Télécharger les fichiers interlis sur le site de l'Asit-VD.
2. Créer le schéma et la structure du modèle dans la base de données, sur la base d'un fichier .ili.
3. Importer les fichiers interlis se trouvant dans un dossier renseigné.

Ces trois scripts se touvent dans le dossier /src. Ils peuvent être enchaînés en lançant le script main.sh à la racine du projet.
Un script se lance par la ligne de commande selon l'exemple qui suit:

```sh
main.sh 
```

ou 

```sh
create_schema.sh [options]
```

## Paramétrage

Chaque script peut être lancé individuellement en respectant les paramètres nécessaires au fonctionnement. Ces mêmes scripts peuvent être enchaînés en lançant le script ```main.sh```. Ce dernier est paramétré grâce à un fichier .env. Le fichier .envexample indique les variables d'environnement à définir pour le bon fonctionnement du script.

## Scripts

Les scripts sont succintement décrits ci-dessous.

### download_itf.sh

Ce script permet de télécharger les fichiers interlis se trouvant sur le site de l'AVRIC (viageo.ch/api/download/..., option ```-l```), en utilisant une _basic authentication_ (```-a```). La liste des fichiers à télécharger est sous la forme d'un fichier json construit comme suit:

```json
{
    "5402": 2,
    "5406": 6,
    "5409": 9,
    ...
}
```

Chaque clé est un numéro de commune fédéral (OFS), chaque valeur son numéro de commune cantonal équivalent. Le chemin vers la fichier json est à renseigner pour l'option ```-c```. Les fichier sont téléchargés dans le dossier passé à l'option ```-f```.

L'appel du script peut ressembler à 

```sh
src/download_itf.sh -l "viageo.ch/api/download/my_link" -a "basic my_auth" -c "/home/my_role/communes.json" -f "/tmp/my_download_directory/"
```

### create_schema.sh

Ce script permet de créer le schéma dans lequel seront importées les données. L'essentiel des options du script sont utilisées pour le passage des information de connexion à la base de données: ```[-U USER]```, ```[-H HOST]```, ```[-p PORT]```, ```[-s SCHEMA]```, ```[-d DATABASE]```, ```[-w PASSWORD]```. Un pg_service n'est pas utilisé car ili2db ne permet pas leur utilisation au moment d'écrire ce texte. 

Les options restantes permettent de paramétrer la création du schéma:
* ```-E```/```--createEnumTabs``` --> Crée une table avec les différentes valeurs d'énumération pour chaque définition d'énumération.
* ```-T```/```--createTidCol``` --> Crée une colonne supplémentaire T_Ili_Tid dans chaque table.
* ```-B```/```--createBasketCol``` --> Crée dans chaque table une colonne supplémentaire T_basket pour pouvoir identifier le conteneur.
* ```-n t_id``` --> Le nom de la colonne t_id.
* ```-m interlis_model``` --> Le chemin vers le model interlis (.ili) à construire.

Un exemple d'appel du script ci-dessous:

```sh
src/create_schema.sh -d my_db -h my_host -p 5432 -s my_schema -U username -w password -E -T -B -n "fid" -m "/path/to/my/model.ili"
```

### drop_schema.sh

Le script antagoniste à ```create_schema.sh```. Il permet de supprimer un schéma dans une base de données. Ici un pg_service est utilisé pour stocker les informations de connexion. Pas franchement plus rapide que ```psql service=my_service -c 'DROP my_schema CASCADE;'```

### import_itf.sh

Ce script réalise l'essentiel du travail, et la très large majorité du temps de traitement lui incombe. Il parcours un dossier contenant une liste de fichiers interlis et importe chacun dans la base de données correspondant aux informations de connexion données. La création préalable d'un schéma avec la structure de modèle adapatée aux données importées est obligatoire.

Comme dans le cas du script ```create_schema.sh```, une bonne partie des options récupèrent les informations de connexion: ```[-U USER]```, ```[-H HOST]```, ```[-p PORT]```, ```[-s SCHEMA]```, ```[-d DATABASE]```, ```[-w PASSWORD]```.

Le chemin vers le dossier contentant les fichiers interlis (potentiellement le même que celui de téléchargement) est donné par le paramètre ```-f source folder```. Le paramètre ```-n tid_name``` indique le nom de la colonne _tid_ utilisé lors de la création du schéma.

Si l'on considère le dossier de téléchargement utilisé dans l'exemple de ```download_itf.sh```, un appel de ```import_itf.sh``` pourrait ressembler à:

```sh
src/import_itf.sh -d my_db -h my_host -p 5432 -s my_schema -U username -w password -f "/tmp/my_download_directory/" -n "fid"
```

### main.sh

Le script privilégié pour intéragir avec cet ensemble. Il permet d'appeler les différents scripts et de centraliser les variables. Il utilise un ficher ```.env``` pour la lecture des variables et ainsi éviter d'exposer certaines valeurs. Dans son état actuel, le script travail explicitement sur des données MO et des données NPCS, rendant son design assez grossier avec des répétitions d'opérations, ainsi que des traitements très liés au processus en place, et impossible à utiliser dans un autre contexte. Un effort de refactorisation sera le bienvenu.

Les variables d'environnement lues sont les suivantes:
* ```MOVD_DOWNLOAD_LINK``` --> URL de téléchargement des fichiers interlis MO
* ```NPCSVD_DOWNLOAD_LINK``` --> URL de téléchargement des fichiers interlis NPCS
* ```AUTHORIZATION``` --> Authentification à l'api de téléchargement
* ```DATABASE``` --> le nom de la base de données hébergeant l'import
* ```HOST``` --> le hos de la base de données
* ```USER``` --> _username_ pour le traitement dans la base de données
* ```PASSWORD``` --> le mot de passe pour la connexion à la base de données
* ```PORT``` --> le port de connexion à la base de données
* ```MOVD_SCHEMA``` --> le nom du schéma recevant les données MO
* ```NPCSVD_SCHEMA``` --> le nom du schéma recevant les données NPCS
* ```T_ID_NAME``` --> le nom de la colonne t_id (identifiant système dans la base de données)

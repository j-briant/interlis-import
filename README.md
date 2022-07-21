# import-interlis-mensuration-officielle

A script for looping through a folder an load interlis files into a database.

## Objectifs

Le but est d'automatiser l'import des données cantonales localement, en limitant le nombre de scripts et d'outils utilisés. Conserver la structure du modèle MD.01-MO-CH est également voulu pour pouvoir dénormaliser et garder le contrôle au sein de la base de données, et non lors de processsus d'import ou d'export.

## Outils

Il s'agit essentiellement de scripts batch/shell. Les opérations demandent de télécharger, manipuler des fichiers et de communiquer avec une base de données. Le coeur des opérations se fait grâce à [ili2db](https://github.com/claeis/ili2db).

## Fonctionnement

Trois opérations peuvent être réalisées indépendamment ou enchaînées:
1. Télécharger les fichiers interlis sur le site de l'Asit-VD.
2. Créer le schéma et la structure du modèle dans la base de données, sur la base d'un fichier .ili.
3. Importer les fichiers interlis se trouvant dans un dossie renseigné.

Ces trois scripts se touvent dans le dossier /src. Ils peuvent être enchaînés en lançant le script main.bat à la racine du projet.
Un script se lance depuis Windows en double cliquant sur un des script.

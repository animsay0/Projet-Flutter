# 📱Juno - Carnet de voyage

## Description du projet

**Juno** est une application mobile de carnet de voyage qui permet aux utilisateurs de sauvegarder, consulter et gérer leurs sorties et activités. L'application est conçue pour les voyageurs, randonneurs et explorateurs qui souhaitent conserver une trace de leurs aventures.

- **Objectif principal** : Enregistrer des sorties avec des détails tels que le lieu, la date, une note, des photos et des notes personnelles.
- **Public cible** : Amateurs de plein air, voyageurs et toute personne souhaitant documenter ses expériences.
- **Problématique** : Offrir un moyen simple et centralisé de conserver des souvenirs de voyage, enrichis d'informations contextuelles comme la météo et la géolocalisation.

---

## ⚙️ Environnement technique

### Versions utilisées

- **Flutter** : `3.19.0` ou supérieur
- **Dart** : `3.3.0` ou supérieur

*(Veuillez vérifier vos versions avec `flutter --version` et mettre à jour si nécessaire)*

---

## Écrans & fonctionnalités

### Écran 1 : Accueil (`HomeScreen`)
- **Description** : Affiche la liste de toutes les sorties enregistrées. Un en-tête affiche des statistiques clés (nombre de sorties, note moyenne, nombre de sorties "top").
- **Fonctionnalités** :
    - Visualisation des cartes de chaque sortie.
    - Filtrage des sorties par note (de 1 à 5 étoiles).
    - Navigation vers l'écran de détail en cliquant sur une carte.

### Écran 2 : Rechercher (`SearchScreen`)
- **Description** : Permet de rechercher des lieux en utilisant l'API Foursquare. Les résultats peuvent être enrichis avec des données météo.
- **Fonctionnalités** :
    - Recherche par nom de lieu.
    - Recherche de lieux à proximité en utilisant le GPS.
    - Sélection d'un lieu pour créer une nouvelle sortie pré-remplie.

### Écran 3 : Nouvelle Sortie (`AddTripScreen`)
- **Description** : Formulaire pour ajouter une nouvelle sortie. Peut être pré-rempli à partir de l'écran de recherche.
- **Fonctionnalités** :
    - Saisie du titre, lieu, date.
    - Prise de photo avec la caméra ou sélection depuis la galerie.
    - Attribution d'une note (1 à 5).
    - Enregistrement de la sortie.

### Écran 4 : Détail de la Sortie (`TripDetailScreen`)
- **Description** : Affiche toutes les informations détaillées d'une sortie sélectionnée.
- **Fonctionnalités** :
    - Affichage de la photo, du titre, du lieu, de la date, de la note.
    - Affichage des coordonnées GPS.
    - Suppression de la sortie (avec confirmation).

---

## API utilisées

- **Foursquare Places API** : Utilisée pour la recherche de lieux et d'informations détaillées (catégorie, adresse, etc.).
- **OpenWeatherMap API** : Utilisée pour récupérer les conditions météorologiques actuelles (temps et température) pour un lieu donné.
- **OpenStreetMap** : Utilisé pour l'affichage des tuiles de la carte dans `MapScreen`.

---

## Autorisations nécessaires (Android / iOS)

- **Internet** : Nécessaire pour communiquer avec les API Foursquare et OpenWeatherMap, ainsi que pour charger les images et les tuiles de la carte.
- **Localisation** (`ACCESS_FINE_LOCATION`) : Requise pour la fonctionnalité "Lieux à proximité" sur l'écran de recherche.
- **Caméra** (`CAMERA`) : Requise pour prendre des photos et les associer à une sortie.
- **Stockage** (`READ_EXTERNAL_STORAGE` / `WRITE_EXTERNAL_STORAGE` - pour les anciennes versions d'Android) : Potentiellement requis pour la gestion des photos de la galerie.

---

## Dépendances principales

- `shared_preferences`: Pour la persistance des données des voyages.
- `http`: Pour effectuer des requêtes aux API distantes.
- `geolocator`: Pour accéder à la position GPS de l'utilisateur.
- `image_picker`: Pour prendre des photos avec la caméra ou en sélectionner depuis la galerie.
- `intl`: Pour le formatage des dates.
- `flutter_map`: Pour l'affichage de la carte.

---

## Lancement du projet



```bash
git checkout main
flutter pub get
flutter run
```
*Si la branche main ne fonctionne pas aller sur la dev*

---

## 👤 Auteurs

- ALIDOU Yasmina
- AMAH Gaétan

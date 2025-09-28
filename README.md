# Tasker - macOS Menubar App

Tasker est une application macOS légère qui s'intègre à votre barre de menus. Elle vous permet de visualiser et de gérer vos tâches en interagissant avec une API REST.

## ✨ Fonctionnalités

-   **Accès Rapide** : S'ouvre depuis une icône dans la barre de menus de macOS.
-   **Vue des Tâches** : Affiche les tâches du jour et en retard.
-   **Édition en Ligne** : Double-cliquez sur le titre d'une tâche pour le modifier directement.
-   **Gestion des Sous-tâches** : Affichez et marquez les sous-tâches comme complétées dans une section dépliable.
-   **Filtrage Dynamique** : Filtrez les tâches par projet et par étiquettes (sélection multiple).
-   **Tri des Tâches** : Triez les tâches par date d'échéance, priorité ou ordre par défaut.
-   **Complétion de Tâches** : Marquez une tâche ou une sous-tâche comme complétée d'un simple clic.
-   **Rafraîchissement Automatique** : Les données se synchronisent automatiquement toutes les 5 minutes, ou manuellement via un bouton.
-   **Synchronisation Sécurisée** : Vos modifications locales ne sont jamais écrasées par un rafraîchissement.
-   **Localisation** : Interface disponible en Anglais et en Français.

## 🛠️ Architecture

L'application est construite en **Swift** et **SwiftUI** en suivant des principes modernes :

-   **Architecture MVVM** : Le code est organisé en Modèles, Vues et ViewModels pour une séparation claire des responsabilités.
    -   **Model** : Structures `Codable` qui représentent les données de l'API (`Task`, `Project`, etc.). Les propriétés sont mutables (`var`) pour permettre l'édition.
    -   **View** : Vues SwiftUI qui constituent l'interface utilisateur. Elles utilisent `@State` et `@FocusState` pour gérer l'état local de l'UI comme l'édition en ligne.
    -   **ViewModel** (`TaskListViewModel`) : Contient la logique métier, la gestion de l'état (`@Published` properties) et sert de pont entre les Vues et les Services.
-   **Couche Réseau Basée sur les Protocoles** : La communication avec l'API est gérée par un `NetworkService` qui se conforme à un protocole (`NetworkServiceProtocol`). Cela permet d'injecter une version "mock" (`MockNetworkService`) pour les tests et les prévisualisations SwiftUI.
-   **Données Mock Fiables** : Les données de test sont compilées directement dans l'application (`MockData.swift`) pour garantir que les tests et les prévisualisations SwiftUI fonctionnent de manière fiable sans dépendre de fichiers externes.
-   **Programmation Asynchrone** : Utilise `async/await` pour des appels réseau non-bloquants et un code plus lisible.
-   **Combine Framework** : Utilisé pour le *debouncing* des mises à jour, afin de ne pas surcharger l'API avec des requêtes `PATCH` trop fréquentes.

## ⚙️ Configuration et Lancement

### Prérequis

-   macOS 12.0+
-   Xcode 14.0+

### Compilation et Exécution

1.  **Cloner le dépôt** :
    ```bash
    git clone <repository-url>
    cd tasker-macos-app
    ```
2.  **Ouvrir le projet** :
    - Le projet n'a pas de fichier `.xcodeproj` car il a été créé fichier par fichier. Pour l'ouvrir dans Xcode :
      1. Lancez Xcode.
      2. Choisissez "Open a project or file".
      3. Naviguez jusqu'au répertoire racine du projet et sélectionnez le dossier.
    - Alternativement, vous pouvez créer un projet "macOS App" dans Xcode et y glisser/déposer les fichiers créés.
3.  **Configurer l'API (placeholder)** :
    - Ouvrez `Tasker/Service/NetworkService.swift`.
    - Remplacez l'URL de base et les identifiants d'authentification par les vôtres :
      ```swift
      private let baseURL = URL(string: "VOTRE_URL_API")!
      // ...
      let username = "VOTRE_USERNAME"
      let password = "VOTRE_PASSWORD"
      ```
4.  **Lancer l'application** :
    - Sélectionnez la cible `Tasker` et un simulateur ou votre Mac.
    - Appuyez sur le bouton "Run" (▶) ou utilisez le raccourci `Cmd+R`.
    - L'icône de l'application (une checklist) apparaîtra dans la barre de menus de macOS.

## 🧪 Tests

Le projet inclut des tests unitaires pour valider les composants clés de l'application.

### Lancer les Tests

1.  Ouvrez le projet dans Xcode.
2.  Allez dans le menu "Product" et choisissez "Test", ou utilisez le raccourci `Cmd+U`.

### Couverture des Tests

-   **Décodage des Modèles** (`DecodingTests`): Vérifie que les modèles Swift peuvent décoder correctement le JSON de l'API.
-   **Service Réseau Mock** (`NetworkServiceTests`): S'assure que le service mock charge les données statiques comme prévu.
-   **ViewModel** (`TaskListViewModelTests`): Teste la logique de récupération des données, de filtrage et de mise à jour.

## 📁 Structure du Projet

```
Tasker/
├── App/
│   └── TaskerApp.swift      # Point d'entrée de l'application (MenuBarExtra)
├── Model/                   # Structures de données (Codable)
│   ├── APIResponse.swift, Label.swift, Project.swift, Task.swift
├── Resources/               # Fichiers de localisation
│   ├── en.lproj/Localizable.strings
│   └── fr.lproj/Localizable.strings
├── Service/                 # Couche réseau
│   ├── MockData.swift       # Données statiques pour les tests/previews
│   ├── MockNetworkService.swift
│   ├── NetworkService.swift
│   └── NetworkServiceProtocol.swift
├── View/                    # Vues SwiftUI
│   ├── ContentView.swift, ErrorBanner.swift, SubtaskRowView.swift
│   ├── TaskListView.swift, TaskRowView.swift
└── ViewModel/
    └── TaskListViewModel.swift # Logique métier et état de l'UI

TaskerTests/
├── Fixtures/                # (Supprimé, remplacé par MockData.swift)
├── Model/
│   └── DecodingTests.swift
├── Service/
│   └── NetworkServiceTests.swift
└── ViewModel/
    └── TaskListViewModelTests.swift
```
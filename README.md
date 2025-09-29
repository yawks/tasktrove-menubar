# Tasker - macOS Menubar App

Tasker est une application macOS légère qui s'intègre à votre barre de menus. Elle vous permet de visualiser et de gérer vos tâches en interagissant avec une API REST.

## 🚀 **Action Requise : Activer les Connexions Réseau**

**Avant toute chose, pour que l'application puisse se connecter à internet, vous devez effectuer la manipulation suivante dans Xcode. Sans cela, vous aurez une erreur "server with the specified hostname could not be found".**

1.  Dans Xcode, cliquez sur la racine du projet `Tasker` (l'icône bleue).
2.  Sélectionnez la cible **`Tasker`**.
3.  Allez dans l'onglet **"Signing & Capabilities"**.
4.  Cliquez sur **"+ Capability"** et ajoutez la capacité **"App Sandbox"**.
5.  Dans la nouvelle section "App Sandbox" qui apparaît, sous-section **"Network"**, cochez la case **"Outgoing Connections (Client)"**.

![Instructions pour le Sandbox](https://i.imgur.com/8n41d7o.png)

---

## ✨ Fonctionnalités

-   **Accès Rapide** : S'ouvre depuis une icône dans la barre de menus de macOS.
-   **Configuration Dynamique** : Un écran de configuration permet de saisir l'endpoint de l'API et les identifiants. Les mots de passe sont stockés de manière sécurisée dans le Trousseau d'accès (Keychain) de macOS.
-   **Édition en Ligne** : Double-cliquez sur le titre d'une tâche pour le modifier directement.
-   **Gestion des Sous-tâches** : Affichez et marquez les sous-tâches comme complétées dans une section dépliable.
-   **Filtrage & Tri** : Filtrez les tâches par projet et par étiquettes, et triez-les par date, priorité ou ordre par défaut.
-   **Pagination** : La liste est paginée pour une meilleure lisibilité.
-   **Localisation** : Interface disponible en Anglais et en Français.

---

## ⚙️ Installation et Lancement

### 1. Créer le Projet dans Xcode

Comme je ne peux pas générer de fichier `.xcodeproj`, vous devez créer un projet vide et y ajouter les fichiers :

1.  Lancez Xcode et choisissez **"Create a new Xcode project"**.
2.  Sélectionnez **macOS > App**.
3.  Nommez-le `Tasker`, choisissez l'interface **SwiftUI** et le langage **Swift**. Cochez "Include Tests".
4.  Supprimez les fichiers `TaskerApp.swift` et `ContentView.swift` créés par défaut.
5.  Glissez-déposez les dossiers `App`, `Model`, `Resources`, `Service`, `View`, `ViewModel` de ce projet dans le navigateur de fichiers de Xcode. Assurez-vous que **"Copy items if needed"** et **"Create groups"** sont cochés, et que la cible est bien `Tasker`.
6.  Faites de même pour le dossier de tests, en glissant le dossier `TaskerTests` de ce projet sur le dossier `TaskerTests` de Xcode, en vous assurant que la cible est `TaskerTests`.

### 2. Lancer l'Application

-   Appuyez sur **`Cmd + R`** pour lancer l'application.
-   La première fois, l'écran de configuration apparaîtra. Entrez l'URL complète de votre endpoint (ex: `https://mon-api.com/api`), votre login et mot de passe, puis cliquez sur "Test & Save".
-   L'icône de l'application (une checklist) apparaîtra dans la barre de menus.

---

## 🛠️ Architecture

L'application est construite en **Swift** et **SwiftUI** en suivant l'architecture **MVVM**.
-   **Model** (`TodoTask`, `Project`, etc.) : Structures `Codable` qui représentent les données de l'API.
-   **View** (`ContentView`, `SettingsView`, etc.) : Vues SwiftUI qui constituent l'interface utilisateur.
-   **ViewModel** (`TaskListViewModel`, `SettingsViewModel`) : Contient la logique métier et l'état de l'UI.
-   **Service** (`NetworkService`, `ConfigurationService`, `KeychainHelper`) : Couche de service pour la communication réseau et la gestion de la configuration.
-   **Tests** : Des tests unitaires valident le décodage des modèles et la logique du ViewModel.
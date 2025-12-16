# TaskTrove MenuBar

A native macOS app for managing your [TaskTrove](https://github.com/dohsimpson/TaskTrove) tasks directly from the menu bar. Quickly access your tasks, create new ones, and manage your projects without leaving your workflow.

## ✨ Features

- **Native menu bar interface**: Quick access from the macOS menu bar
- **Complete task management**: Create, edit, delete, and mark as complete
- **Advanced filtering**: Filter by project, labels, due date (Inbox, Today, Upcoming, Completed)
- **Flexible sorting**: Sort by due date, priority, or default order
- **Project and label management**: Organize your tasks with colorful projects and labels
- **Subtasks**: Create and manage subtasks for your main tasks
- **Comments**: Add comments to your tasks
- **Automatic synchronization**: Automatic synchronization with the TaskTrove API every 5 minutes
- **Local caching**: Instant display of cached data
- **Security**: Secure storage of API credentials in the macOS Keychain

## 🚀 Installation

### Prerequisites

- macOS 13.0 (Ventura) or higher (MenuBarExtra requires macOS 13+)
- Xcode 14.0 or higher (for compiling from source)
- Access to a TaskTrove instance with a valid API key

### Installation from source

1. Clone the repository:
```bash
git clone https://github.com/yawks/tasktrove-menubar.git
cd tasktrove-menubar
```

2. Open the project in Xcode:
```bash
open tasktrove-menubar.xcodeproj
```

3. Compile and run the project (⌘R)

To create a DMG for local distribution:
```bash
./scripts/build_release_dmg.sh
```

The DMG will be created on your Desktop (`~/Desktop/TaskTroveMenuBar.dmg`).

**Note**: This application is not publicly distributed. You must compile it from source.

### Configuration

1. Launch the application from the menu bar
2. Click on the checklist icon in the menu bar
3. Configure your API endpoint and API key in the settings
4. The application will automatically connect and load your tasks

## 📖 Usage

### Quick access

- **Left-click** on the icon in the menu bar: Opens the main panel
- **Right-click** on the icon: Context menu with Quit option

### Create a task

1. Click on the “New” button in the interface
2. Fill in the details (title, description, due date, project, labels, etc.)
3. Click on “Create Task”

### Filter and sort

- **Quick filters**: Use the Inbox, Today, Upcoming, and Completed buttons
- **Advanced filters**: Click “Filters” to filter by project or labels
- **Sort**: Use the sort button to change the display order

### Edit a task

- **Double-click** on a task to open the detail view
- Edit the fields directly in the detail view
- Changes are saved automatically with a delay of 500ms

## 🛠️ Development

### Project structure

```
tasktrove-menubar/
├── tasktrove-menubar/
│   ├── App/              # Application entry point
│   ├── Model/            # Data models (TodoTask, Project, Label)
│   ├── View/             # SwiftUI views
│   ├── ViewModel/        # ViewModels and business logic
│   ├── Service/          # Services (Network, Configuration, Settings)
│   └── Resources/        # Resources (localizations, assets)
├── scripts/               # Build scripts
└── tasktrove-menubar.xcodeproj/
```

### Technologies used

- **SwiftUI**: Modern, declarative user interface
- **Combine**: Reactive data management
- **AppKit**: Integration with the macOS menu bar
- **URLSession**: Communication with the TaskTrove API
- **Keychain Services**: Secure storage of credentials

### Build and distribution

#### Development build

```bash
xcodebuild -project tasktrove-menubar.xcodeproj \
           -scheme tasktrove-menubar \
           -configuration Debug \
           CONFIGURATION_BUILD_DIR=./build/Debug \
           build
```

#### Release build and DMG creation

```bash
./scripts/build_release_dmg.sh
```

Available options:
- `--dry-run`: Displays commands without executing them
- `--no-clean`: Skips the cleanup step
- `--dmg-name NAME`: Name of the DMG volume (default: TaskTroveMenuBar)
- `--output PATH`: DMG output path
- `--sign`: Signs the application if `CODESIGN_ID` is defined

Example with code signing:
```bash
CODESIGN_ID="Developer ID Application: Your Name (TEAMID)" \
./scripts/build_release_dmg.sh --sign
```

### Debugging in VS Code

The project includes a debug configuration for VS Code. Make sure you have installed the **CodeLLDB** extension:

1. Install CodeLLDB from the VS Code marketplace
2. Use the “Launch TaskTrove (lldb)” configuration in `.vscode/launch.json`
3. Press F5 to start debugging


## 🔧 API Configuration

The application requires:

- **API Endpoint**: Base URL of your TaskTrove instance (e.g., `https://api.tasktrove.example.com`)
- **API Key**: Bearer authentication token to access the API

Credentials are stored securely in the macOS Keychain.

For more information on the TaskTrove API, see the [official documentation](https://developer.tasktrove.io/api).

### Date Format

The API expects dates in the format `yyyy-MM-dd` for the `dueDate` field. The application automatically converts dates to the required format.

## 📝 Data format

### Task (TodoTask)

```swift
struct TodoTask {
    let id: String?
    var title: String
    var description: String?
    var completed: Bool?
    var priority: Int?           // 1-3 (1 = high priority)
    var dueDate: String?        // Format: yyyy-MM-dd
    var projectId: String?
    var sectionId: String?
    var labels: [String]?
    var subtasks: [TodoSubtask]?
    var comments: [Comment]?
    // ...
}
```

## 🐛 Troubleshooting

### The application does not connect to the API

1. Verify that your API endpoint is correct and accessible
2. Verify that your API key is valid
3. Check the logs in the console for detailed errors

### Changes are not saved

- Changes are saved automatically with a delay of 500ms
- Check your network connection
- Check the logs for validation errors (date format, etc.)

### The application does not appear in the menu bar

- Check that the application is running (it appears in the Dock)
- The application uses `LSUIElement = YES`, so it does not appear in the Dock but only in the menu bar

## 📄 License

This project is licensed under MIT. See the LICENSE file for more details.

## 🤝 Contribution

Contributions are welcome! Feel free to open an issue or pull request.

## 🔗 Links

- [TaskTrove](https://github.com/dohsimpson/TaskTrove) - Main TaskTrove project (self-hosted task manager)
- [TaskTrove API Documentation](https://developer.tasktrove.io/api) - Complete API documentation
- [Issues](https://github.com/yawks/tasktrove-menubar/issues) - Report a bug or request a feature


macOS client application for [TaskTrove](https://github.com/dohsimpson/TaskTrove), a modern, self-hostable task manager.

---

**Note**: This application requires a working TaskTrove instance to function. Make sure you have access to an instance and a valid API key before using it.
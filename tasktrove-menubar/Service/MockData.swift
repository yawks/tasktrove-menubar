import Foundation

struct MockData {
    static let tasksJSON = """
    {
      "tasks": [
        {
          "id": "1888c17f-5935-4468-b26e-c53ff937be3c",
          "title": "Multi collections et DMRag et fichiers uploadés",
          "description": "Voir ticket RDA-6490",
          "completed": false,
          "priority": 2,
          "dueDate": "2025-09-29",
          "projectId": "42812db3-12a7-44e0-93da-7dafbf91019e",
          "sectionId": "00000000-0000-0000-0000-000000000000",
          "labels": [
            "1fa925ad-0d1e-4132-8f81-d402a1216c5b",
            "86e10821-45a6-4d0a-83bb-d30c676e39e5"
          ],
          "subtasks": [
            {
              "id": "508029ba-2130-4a0c-8c40-b3ab6d1feb29",
              "title": "Sous-tâche 1: Reformulation",
              "completed": false,
              "order": 0
            },
            {
              "id": "76f548f7-65a9-402a-8067-9db7fe2654cd",
              "title": "Sous-tâche 2: Classification",
              "completed": true,
              "order": 1
            }
          ],
          "comments": [],
          "attachments": [],
          "createdAt": "2025-09-22T13:10:45.620Z",
          "status": "active",
          "recurringMode": "dueDate"
        }
      ],
      "projects": [
        {
          "id": "42812db3-12a7-44e0-93da-7dafbf91019e",
          "name": "Dydu",
          "slug": "dydu",
          "color": "#3b82f6",
          "shared": false,
          "sections": [
            {
              "id": "00000000-0000-0000-0000-000000000000",
              "name": "Backlog",
              "color": "#f97316"
            },
            {
              "id": "678418e6-dcfc-40ce-90f0-7af45132f5f0",
              "name": "En cours",
              "color": "#ec4899"
            }
          ],
          "taskOrder": [
            "1888c17f-5935-4468-b26e-c53ff937be3c"
          ]
        }
      ],
      "labels": [
        {
          "id": "86e10821-45a6-4d0a-83bb-d30c676e39e5",
          "name": "Base de connaissance",
          "slug": "base-de-connaissance",
          "color": "#6366f1"
        },
        {
          "id": "c1e2cfba-4d67-432d-8082-926740d74fd2",
          "name": "Interne",
          "slug": "interne",
          "color": "#ef4444"
        },
        {
            "id": "1fa925ad-0d1e-4132-8f81-d402a1216c5b",
            "name": "Frontend",
            "slug": "frontend",
            "color": "#f43f5e"
        }
      ],
      "projectGroups": { "type": "project", "id": "00000000-0000-0000-0000-000000000000", "name": "All Projects", "slug": "all-projects", "items": ["42812db3-12a7-44e0-93da-7dafbf91019e"] },
      "labelGroups": { "type": "label", "id": "00000000-0000-0000-0000-000000000000", "name": "All Labels", "slug": "all-labels", "items": ["6ba7b811-9dad-41d1-8696-f01c6a84b1a1"] },
      "version": "v0.6.0"
    }
    """
}
# Focal — Arquitectura iOS (Swift 6, offline-first, BYOK)

## 1. Estructura de módulos

Local Swift Packages, no un solo target monolítico. Esto fuerza límites de dependencia reales (el compilador rompe si Presentation importa Data directamente).

```
Focal/
├── Package.swift / Focal.xcodeproj
├── App/                          # composition root, entry point, DI wiring
│   ├── FocalApp.swift
│   ├── MainTabView.swift
│   └── AppDependencyContainer.swift
├── Packages/
│   ├── DesignSystem/             # tokens, componentes SwiftUI reutilizables
│   ├── Domain/                   # entidades puras, protocolos de repos/servicios, use cases
│   │   └── Sources/Domain/
│   │       ├── Entities/
│   │       ├── Repositories/     # protocolos, sin implementación
│   │       └── UseCases/
│   ├── Data/                     # SwiftData, Keychain, implementaciones de Domain/Repositories
│   │   └── Sources/Data/
│   │       ├── Persistence/      # @Model, SwiftDataStack
│   │       ├── Security/         # KeychainService
│   │       └── Repositories/     # implementaciones concretas
│   ├── AIKit/                    # AIServiceProtocol + providers (Gemini/OpenAI)
│   ├── TimerKit/                 # motor de temporizador + Live Activities
│   └── Presentation/             # Features en MVVM-C
│       └── Sources/Presentation/
│           ├── Timeline/
│           ├── BrainDump/
│           ├── Focus/
│           └── Settings/
```

Regla de dependencia: `Presentation → Domain ← Data`, `Presentation → AIKit/TimerKit → Domain`. Data y AIKit nunca se importan entre sí ni se importan en Presentation directamente — todo pasa por protocolos de Domain. Esto es lo que te permite testear Presentation con mocks sin SwiftData ni red real.

## 2. Esquema SwiftData

```swift
enum FocalSchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] {
        [DailyPlan.self, TimeBlock.self, TaskItem.self, BrainDumpEntry.self]
    }
}
```

Migration plan:
```swift
enum FocalMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [FocalSchemaV1.self] }
    static var stages: [MigrationStage] { [] }
}
```

## 3. Keychain — API Keys

```swift
protocol APIKeyStoring: Sendable {
    func save(_ key: String, for provider: AIProvider) throws
    func retrieve(for provider: AIProvider) throws -> String?
    func delete(for provider: AIProvider) throws
}
```

## 4. Motor de IA — `AIServiceProtocol`

```swift
protocol AIServiceProtocol: Sendable {
    func parseBrainDump(_ text: String) async throws -> [ParsedTaskSuggestion]
}

struct ParsedTaskSuggestion: Codable, Sendable, Identifiable {
    let id: UUID
    let title: String
    let suggestedStartTime: String?
    let estimatedMinutes: Int?
}
```

## 5. Timer + Live Activities

`FocusTimerEngine` actor & `FocusActivityController` (ActivityKit throttled state updates).

# Focal — Arquitectura iOS (Swift 6, offline-first, BYOK)

## 1. Estructura de módulos

Local Swift Packages, no un solo target monolítico. Esto fuerza límites de dependencia reales (el compilador rompe si Presentation importa Data directamente).

```
Focal/
├── Focal.xcodeproj
├── App/                          # composition root, entry point, DI wiring
│   └── FocalApp.swift
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

No uses Clean Architecture "de libro" con 4 capas y mappers en cada capa — es overkill para un solo dev shippeando rápido. Con Domain (protocolos + entidades) y Data (implementación) ya tienes el 90% del beneficio (testability, swap de providers) con la mitad del código.

## 2. Esquema SwiftData

Puntos de diseño:
- `DailyPlan` es el agregado raíz por día (una entidad por fecha calendario, normalizada a medianoche local).
- Cascade delete de `DailyPlan → TimeBlock → TaskItem`.
- `BrainDumpEntry` vive independiente, se "promueve" a `TaskItem`/`TimeBlock` por acción explícita del usuario, no por relación automática.
- Usa `@Attribute(.unique)` donde aplique para evitar duplicados en imports/sync futuro.
- Deja espacio para migraciones: todo modelo v1 debe anticipar un `SchemaMigrationPlan` desde el día uno, aunque hoy solo tengas un `VersionedSchema`.

```swift
import SwiftData
import Foundation

// MARK: - Schema V1

enum FocalSchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] {
        [DailyPlan.self, TimeBlock.self, TaskItem.self, BrainDumpEntry.self]
    }
}

@Model
final class DailyPlan {
    @Attribute(.unique) var dayIdentifier: String   // "yyyy-MM-dd", clave estable
    var date: Date

    @Relationship(deleteRule: .cascade, inverse: \TimeBlock.plan)
    var timeBlocks: [TimeBlock] = []

    init(date: Date) {
        self.date = Calendar.current.startOfDay(for: date)
        self.dayIdentifier = Self.identifier(for: date)
    }

    static func identifier(for date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = .current
        return f.string(from: date)
    }
}

@Model
final class TimeBlock {
    var title: String
    var startTime: Date
    var endTime: Date
    var colorHex: String
    var icon: String
    var isCompleted: Bool = false
    var sortOrder: Int = 0

    var plan: DailyPlan?

    @Relationship(deleteRule: .cascade, inverse: \TaskItem.timeBlock)
    var tasks: [TaskItem] = []

    init(title: String, startTime: Date, endTime: Date, colorHex: String, icon: String) {
        self.title = title
        self.startTime = startTime
        self.endTime = endTime
        self.colorHex = colorHex
        self.icon = icon
    }
}

@Model
final class TaskItem {
    var title: String
    var isDone: Bool = false
    var notes: String?
    var sortOrder: Int = 0

    var timeBlock: TimeBlock?

    init(title: String, notes: String? = nil) {
        self.title = title
        self.notes = notes
    }
}

@Model
final class BrainDumpEntry {
    @Attribute(.unique) var id: UUID
    var text: String
    var createdAt: Date
    var isProcessed: Bool = false   // true una vez convertido a TaskItem/TimeBlock

    init(text: String) {
        self.id = UUID()
        self.text = text
        self.createdAt = .now
    }
}
```

Migration plan (esqueleto, listo para cuando llegue V2 — ej. agregar `recurrenceRule` a `TimeBlock`):

```swift
enum FocalMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [FocalSchemaV1.self] }
    static var stages: [MigrationStage] { [] }  // agrega .lightweight/.custom aquí en V2
}

@MainActor
enum SwiftDataStack {
    static let container: ModelContainer = {
        let config = ModelConfiguration(isStoredInMemoryOnly: false)
        return try! ModelContainer(
            for: FocalSchemaV1.models.first!, FocalSchemaV1.models.dropFirst().first!,
            migrationPlan: FocalMigrationPlan.self,
            configurations: config
        )
    }()
}
```

## 3. Keychain — API Keys

Protocolo en Domain, implementación en Data. Nunca UserDefaults, nunca en SwiftData (el store no está encriptado a nivel de archivo por default).

```swift
// Domain/Repositories/APIKeyStoring.swift
protocol APIKeyStoring: Sendable {
    func save(_ key: String, for provider: AIProvider) throws
    func retrieve(for provider: AIProvider) throws -> String?
    func delete(for provider: AIProvider) throws
}

enum AIProvider: String, Codable, Sendable {
    case gemini, openAI
}

enum KeychainError: Error {
    case unhandledStatus(OSStatus)
    case encodingFailed
}
```

```swift
// Data/Security/KeychainService.swift
import Security
import Foundation

final class KeychainService: APIKeyStoring {
    private let service = "com.focal.apikeys"

    func save(_ key: String, for provider: AIProvider) throws {
        guard let data = key.data(using: .utf8) else { throw KeychainError.encodingFailed }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: provider.rawValue
        ]
        SecItemDelete(query as CFDictionary) // upsert

        var attributes = query
        attributes[kSecValueData as String] = data
        attributes[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly

        let status = SecItemAdd(attributes as CFDictionary, nil)
        guard status == errSecSuccess else { throw KeychainError.unhandledStatus(status) }
    }

    func retrieve(for provider: AIProvider) throws -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: provider.rawValue,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess, let data = result as? Data else {
            throw KeychainError.unhandledStatus(status)
        }
        return String(data: data, encoding: .utf8)
    }

    func delete(for provider: AIProvider) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: provider.rawValue
        ]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unhandledStatus(status)
        }
    }
}
```

`kSecAttrAccessibleWhenUnlockedThisDeviceOnly`: la key nunca sale del dispositivo, ni siquiera vía iCloud Keychain backup. Correcto para BYOK sensible.

## 4. Motor de IA — `AIServiceProtocol`

Un protocolo, structured output vía JSON schema, providers intercambiables. Nada de SDKs de terceros — `URLSession` puro como pediste.

```swift
// Domain/UseCases/AIServiceProtocol.swift
protocol AIServiceProtocol: Sendable {
    func parseBrainDump(_ text: String) async throws -> [ParsedTaskSuggestion]
}

struct ParsedTaskSuggestion: Decodable, Sendable {
    let title: String
    let suggestedStartTime: String?  // ISO8601 opcional, el modelo puede no saber
    let estimatedMinutes: Int?
}

enum AIServiceError: Error {
    case missingAPIKey
    case invalidResponse
    case rateLimited
    case network(Error)
    case decoding(Error)
}
```

```swift
// AIKit/GeminiAIService.swift
final class GeminiAIService: AIServiceProtocol {
    private let keyStore: APIKeyStoring
    private let session: URLSession

    init(keyStore: APIKeyStoring, session: URLSession = .shared) {
        self.keyStore = keyStore
        self.session = session
    }

    func parseBrainDump(_ text: String) async throws -> [ParsedTaskSuggestion] {
        guard let apiKey = try keyStore.retrieve(for: .gemini) else {
            throw AIServiceError.missingAPIKey
        }

        var request = URLRequest(
            url: URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=\(apiKey)")!
        )
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "contents": [["parts": [["text": prompt(for: text)]]]],
            "generationConfig": [
                "responseMimeType": "application/json",
                "responseSchema": Self.taskListSchema
            ]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw AIServiceError.network(error)
        }

        guard let http = response as? HTTPURLResponse else { throw AIServiceError.invalidResponse }
        if http.statusCode == 429 { throw AIServiceError.rateLimited }
        guard (200...299).contains(http.statusCode) else { throw AIServiceError.invalidResponse }

        do {
            let envelope = try JSONDecoder().decode(GeminiEnvelope.self, from: data)
            guard let jsonText = envelope.candidates.first?.content.parts.first?.text,
                  let jsonData = jsonText.data(using: .utf8) else {
                throw AIServiceError.invalidResponse
            }
            return try JSONDecoder().decode([ParsedTaskSuggestion].self, from: jsonData)
        } catch let e as AIServiceError {
            throw e
        } catch {
            throw AIServiceError.decoding(error)
        }
    }

    private func prompt(for text: String) -> String {
        "Extract discrete tasks from this brain dump. Return only the tasks: \(text)"
    }

    private static let taskListSchema: [String: Any] = [
        "type": "ARRAY",
        "items": [
            "type": "OBJECT",
            "properties": [
                "title": ["type": "STRING"],
                "suggestedStartTime": ["type": "STRING", "nullable": true],
                "estimatedMinutes": ["type": "INTEGER", "nullable": true]
            ],
            "required": ["title"]
        ]
    ]
}

private struct GeminiEnvelope: Decodable {
    struct Candidate: Decodable { struct Content: Decodable { struct Part: Decodable { let text: String }; let parts: [Part] }; let content: Content }
    let candidates: [Candidate]
}
```

`OpenAIAIService` es el mismo shape: mismo protocolo, `response_format: { type: "json_schema" }` en vez de `responseSchema`. No lo dupliques literal — comparte el `prompt(for:)` y el manejo de errores en un `AIServiceErrorMapping` helper si quieres, pero no fuerces una superclase abstracta por dos providers.

Selección de provider en runtime, vía factory simple (no un DI container pesado tipo Swinject — no lo necesitas):

```swift
enum AIServiceFactory {
    static func make(provider: AIProvider, keyStore: APIKeyStoring) -> AIServiceProtocol {
        switch provider {
        case .gemini: GeminiAIService(keyStore: keyStore)
        case .openAI: OpenAIAIService(keyStore: keyStore)
        }
    }
}
```

Inyecta vía `@Environment` custom o init injection en el ViewModel — con este tamaño de app un DI container es abstracción sin retorno.

## 5. Timer + Live Activities sin bloquear el main thread

Arquitectura: el timer "de verdad" vive en un `actor` (fuente de verdad, no UI). SwiftUI observa vía `@Observable` en el main thread solo para pintar; ActivityKit se actualiza de forma independiente y con throttling — no en cada tick.

```swift
// TimerKit/FocusTimerEngine.swift
actor FocusTimerEngine {
    private(set) var remainingSeconds: Int
    private var task: Task<Void, Never>?
    private let onTick: @Sendable (Int) -> Void

    init(duration: Int, onTick: @escaping @Sendable (Int) -> Void) {
        self.remainingSeconds = duration
        self.onTick = onTick
    }

    func start() {
        task?.cancel()
        task = Task {
            while remainingSeconds > 0, !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                remainingSeconds -= 1
                onTick(remainingSeconds)
            }
        }
    }

    func pause() { task?.cancel() }
}
```

Punto clave de batería: **no** actualices el Live Activity cada segundo. iOS ya renderiza countdowns nativos sin wakeups tuyos si usas `Text(timerInterval:)` dentro del widget — le pasas start/end date una sola vez y el sistema anima. Tu update a ActivityKit va solo en eventos de estado (start/pause/resume/finish), no en cada tick.

```swift
// TimerKit/FocusActivityController.swift
import ActivityKit

struct FocusActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var endDate: Date
        var isPaused: Bool
    }
    var blockTitle: String
}

@MainActor
final class FocusActivityController {
    private var activity: Activity<FocusActivityAttributes>?

    func start(title: String, endDate: Date) {
        let attrs = FocusActivityAttributes(blockTitle: title)
        let state = FocusActivityAttributes.ContentState(endDate: endDate, isPaused: false)
        activity = try? Activity.request(
            attributes: attrs,
            content: .init(state: state, staleDate: endDate)
        )
    }

    func pause(currentRemaining: Date) async {
        guard let activity else { return }
        let state = FocusActivityAttributes.ContentState(endDate: currentRemaining, isPaused: true)
        await activity.update(.init(state: state, staleDate: nil))
    }

    func end() async {
        await activity?.end(nil, dismissalPolicy: .immediate)
    }
}
```

Widget (Dynamic Island / Lock Screen):

```swift
Text(timerInterval: Date.now...context.state.endDate, countsDown: true)
```

Esto es literalmente gratis en batería — es rendering declarativo del sistema, no un loop tuyo compitiendo con el estado.

## 6. Errores y edge cases

| Caso | Estrategia |
|---|---|
| API key inválida (401/403) | `AIServiceError` tipado → UI muestra banner inline en Settings/BrainDump, no alert modal bloqueante. Nunca reintentes automático con la misma key. |
| Sin conexión | Detecta con `NWPathMonitor` antes de disparar el request, no dependas solo del catch de `URLSession`. Si offline, deshabilita el botón de "Parse with AI" y muestra el brain dump como texto plano editable manualmente — la app sigue 100% funcional sin IA. |
| Rate limit (429) | Backoff simple (no reintento silencioso indefinido): muestra "límite alcanzado, intenta en unos minutos" y cachea el texto sin perderlo. |
| JSON malformado del LLM | `decoding` error → fallback a mostrar el texto crudo como una sola tarea sin parsear, nunca crashear ni perder el brain dump del usuario. |
| Migración de schema falla | `ModelContainer` con `migrationPlan` explícito desde V1 evita esto a futuro; en dev, nunca borres el store — usa staged migrations reales. |
| Timer y app suspendida (backgrounded) | El `actor` no corre en background; al volver a foreground, recalcula `remainingSeconds` desde `endDate` guardado en SwiftData/UserDefaults, no confíes en el loop de `Task.sleep` haber seguido corriendo. |

## Riesgo principal

Meter DI container o 4 capas "libro de texto" antes de tener 1 usuario real usando el brain dump. Con Domain+Data+Presentation y protocolos ya tienes swap de providers y testability. Todo lo demás (Swinject, Clean Architecture completa, CQRS) es tiempo que no vas a recuperar — valida el flujo BYOK con 5 usuarios reales antes de pulir arquitectura más allá de esto.

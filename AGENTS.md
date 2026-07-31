# AGENTS.md — Focal (iOS)

## Qué es esto

Focal: planificador diario visual estilo Tiimo, nativo iOS 17+. 100% offline-first, cero backend, BYOK (Gemini/OpenAI) para IA. Ver `docs/ARCHITECTURE.md` para el diseño completo — este archivo son las reglas operativas para agentes trabajando en el código.

## Stack (no negociable sin aprobación explícita)

- Swift 6, concurrencia estricta (`Sendable` en todo lo que cruce actor boundaries).
- SwiftUI puro. Nada de UIKit salvo interop inevitable.
- SwiftData para persistencia. Nunca Core Data, nunca Realm.
- Keychain Services para API keys. Nunca UserDefaults para secretos.
- `URLSession` nativo. Nunca Alamofire ni SDKs de terceros para red.
- ActivityKit para Live Activities / Dynamic Island.

## Estructura del repo

```
Focal/
├── App/                # composition root
├── Packages/
│   ├── DesignSystem/
│   ├── Domain/          # entidades + protocolos, sin imports de Data/AIKit
│   ├── Data/            # SwiftData, Keychain, implementaciones de Domain
│   ├── AIKit/           # providers Gemini/OpenAI, implementa AIServiceProtocol
│   ├── TimerKit/        # motor de timer (actor) + Live Activities
│   └── Presentation/    # MVVM-C por feature
```

Regla de dependencia estricta: `Presentation → Domain ← Data`. `Data` y `AIKit` no se importan entre sí ni se importan directo en `Presentation`. Si un agente necesita romper esta regla, debe preguntar antes, no asumir.

## Reglas de código

1. Todo tipo `@Model` de SwiftData vive en `Data/Persistence`, nunca en `Domain`. `Domain` solo ve protocolos de repositorio.
2. `AIServiceProtocol` es la única superficie que `Presentation` conoce del lado de IA. Nunca instancies `GeminiAIService` u `OpenAIAIService` directo en una View o ViewModel — usa `AIServiceFactory` o inyección.
3. API keys: solo vía `APIKeyStoring` (Keychain). Si encuentras una key en código, config, logs o UserDefaults, es un bug — repórtalo, no lo repliques.
4. Nada de DI containers de terceros (Swinject, Factory, etc). Init injection + protocolos es suficiente para este tamaño de app.
5. No agregues capas nuevas (mappers extra, "coordinators" genéricos, CQRS) sin que resuelvan un problema concreto ya presente en el código. Prioriza shipping sobre arquitectura especulativa.
6. Cambios de schema SwiftData: siempre agregar un stage a `FocalMigrationPlan`, nunca mutar un `VersionedSchema` ya shippeado.
7. El timer nunca corre lógica de tick en el main thread ni actualiza ActivityKit en cada segundo — solo en cambios de estado (start/pause/resume/end). Ver `FocusTimerEngine`.

## Testing

- `Domain` y `Data` deben ser testeables sin UI (XCTest, sin necesidad de simulador para lógica pura).
- Mockea `AIServiceProtocol` y `APIKeyStoring` en tests de `Presentation` — nunca golpees red real ni Keychain real en unit tests.

## Qué NO hacer

- No introducir backend, sync remoto ni analytics de terceros sin aprobación explícita — el proyecto es local-first por principio, no por default temporal.
- No usar `print` para debug persistente — usa `os.Logger`.
- No commitear API keys de prueba, ni siquiera en `.xcconfig` ignorado — usa Keychain también en dev/simulador.

## Antes de abrir un PR / entregar trabajo

- Compila sin warnings de concurrencia (`-strict-concurrency=complete`).
- Verifica que `Domain` no importa `Data`, `AIKit` ni `Presentation` (regla de dependencia).
- Si tocaste `AIServiceProtocol` o el schema de SwiftData, actualiza `docs/ARCHITECTURE.md`.

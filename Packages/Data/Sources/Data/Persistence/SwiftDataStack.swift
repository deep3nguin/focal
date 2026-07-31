import SwiftData

@MainActor
public enum SwiftDataStack {
    public static var inMemoryContainer: ModelContainer {
        let schema = Schema(FocalSchemaV1.models)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try! ModelContainer(for: schema, migrationPlan: FocalMigrationPlan.self, configurations: [config])
    }

    public static let container: ModelContainer = {
        let schema = Schema(FocalSchemaV1.models)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, migrationPlan: FocalMigrationPlan.self, configurations: [config])
        } catch {
            // Fallback for previews/tests/recovery if migration plan initialization fails
            return try! ModelContainer(for: schema, configurations: [ModelConfiguration(isStoredInMemoryOnly: true)])
        }
    }()
}

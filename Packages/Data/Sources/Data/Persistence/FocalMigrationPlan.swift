import SwiftData

public enum FocalMigrationPlan: SchemaMigrationPlan {
    public static var schemas: [any VersionedSchema.Type] {
        [FocalSchemaV1.self]
    }

    public static var stages: [MigrationStage] {
        []
    }
}

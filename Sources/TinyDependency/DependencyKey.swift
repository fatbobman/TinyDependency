/// 依赖键协议，定义依赖的类型和不同作用域的默认值
///
/// 实现此协议来定义自定义依赖：
/// ```swift
/// private struct DatabaseKey: DependencyKey {
///     static let defaultValue: Database = SQLiteDatabase()
///     static let testValue: Database = MockDatabase()
///     static let previewValue: Database = InMemoryDatabase()
/// }
/// ```
public protocol DependencyKey {
    /// 依赖值的类型，必须遵循 Sendable 以确保并发安全
    associatedtype Value: Sendable

    /// 生产环境使用的默认值
    static var defaultValue: Value { get }

    /// 测试环境使用的值
    static var testValue: Value { get }

    /// Preview 环境使用的值
    static var previewValue: Value { get }
}

// MARK: - 默认实现

extension DependencyKey {
    /// 默认情况下，testValue 和 previewValue 与 defaultValue 相同
    /// 如果需要不同的值，可以在具体实现中覆盖
    public static var testValue: Value { defaultValue }
    public static var previewValue: Value { defaultValue }
}

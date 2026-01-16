import Foundation

/// Property Wrapper，提供对依赖值的便捷访问
///
/// 使用示例：
/// ```swift
/// class Service {
///     @Dependency(\.logger) var logger
///
///     func doWork() {
///         logger.log("Working...")
///     }
/// }
/// ```
@propertyWrapper
public struct Dependency<Value: Sendable>: @unchecked Sendable {
    private let keyPath: KeyPath<DependencyValues, Value>

    /// 初始化 Dependency
    /// - Parameter keyPath: 指向 DependencyValues 中依赖的 KeyPath
    public init(_ keyPath: KeyPath<DependencyValues, Value>) {
        self.keyPath = keyPath
    }

    /// 获取依赖值
    public var wrappedValue: Value {
        DependencyValues.current[keyPath: keyPath]
    }
}

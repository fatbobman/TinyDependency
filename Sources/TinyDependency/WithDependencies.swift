import Foundation

/// 在指定作用域内临时覆盖依赖值
///
/// 主要用于测试场景，可以临时替换依赖：
/// ```swift
/// withDependencies {
///     $0.logger = MockLogger()
///     $0.database = InMemoryDatabase()
/// } operation: {
///     // 在这个闭包内，使用的是 MockLogger 和 InMemoryDatabase
///     let service = Service()
///     service.doWork()
/// }
/// ```
///
/// - Parameters:
///   - updateValuesForOperation: 用于修改依赖值的闭包
///   - operation: 使用修改后依赖值的操作闭包
/// - Returns: operation 闭包的返回值
public func withDependencies<R>(
    _ updateValuesForOperation: @Sendable (inout DependencyValues) -> Void,
    operation: @Sendable () throws -> R
) rethrows -> R {
    var dependencies = DependencyValues.current.copy()
    updateValuesForOperation(&dependencies)
    return try DependencyValues.$_current.withValue(dependencies) {
        try operation()
    }
}

/// 异步版本的 withDependencies
///
/// 用于异步操作：
/// ```swift
/// await withDependencies {
///     $0.logger = MockLogger()
/// } operation: {
///     await someAsyncWork()
/// }
/// ```
///
/// - Parameters:
///   - updateValuesForOperation: 用于修改依赖值的闭包
///   - operation: 使用修改后依赖值的异步操作闭包
/// - Returns: operation 闭包的返回值
public func withDependencies<R>(
    _ updateValuesForOperation: @Sendable (inout DependencyValues) -> Void,
    operation: @Sendable () async throws -> R
) async rethrows -> R {
    var dependencies = DependencyValues.current.copy()
    updateValuesForOperation(&dependencies)
    return try await DependencyValues.$_current.withValue(dependencies) {
        try await operation()
    }
}

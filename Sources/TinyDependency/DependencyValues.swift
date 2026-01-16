import Foundation

/// 依赖容器，存储和管理所有依赖值
///
/// 通过下标语法访问依赖：
/// ```swift
/// extension DependencyValues {
///     var logger: Logger {
///         get { self[LoggerKey.self] }
///         set { self[LoggerKey.self] = newValue }
///     }
/// }
/// ```
public struct DependencyValues: Sendable {
    private let storage: DependencyStorage

    /// 私有初始化方法
    private init(storage: DependencyStorage) {
        self.storage = storage
    }

    /// 创建默认容器
    static func makeDefault() -> DependencyValues {
        DependencyValues(storage: DependencyStorage())
    }

    /// 下标访问依赖值
    public subscript<Key: DependencyKey>(key: Key.Type) -> Key.Value {
        get {
            if let value = storage.get(key) as? Key.Value {
                return value
            }
            // 根据环境返回不同的默认值
            let defaultValue = Self.defaultValue(for: key)
            storage.set(defaultValue, for: key)
            return defaultValue
        }
        set {
            storage.set(newValue, for: key)
        }
    }

    /// 根据环境获取默认值
    private static func defaultValue<Key: DependencyKey>(for key: Key.Type) -> Key.Value {
        #if DEBUG
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            return Key.previewValue
        }
        // 在 DEBUG 模式下，默认使用 testValue
        // 这样在开发和测试时都会使用 testValue
        return Key.testValue
        #else
        return Key.defaultValue
        #endif
    }

    /// 检测是否在测试环境
    private static var isRunningTests: Bool {
        // 检测 XCTest
        if NSClassFromString("XCTestCase") != nil {
            return true
        }
        // 检测 Swift Testing
        if NSClassFromString("Test") != nil {
            return true
        }
        // 通过环境变量检测
        if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil {
            return true
        }
        return false
    }

    /// 创建副本用于作用域隔离
    func copy() -> DependencyValues {
        DependencyValues(storage: storage.copy())
    }
}

// MARK: - TaskLocal

extension DependencyValues {
    /// 使用 @TaskLocal 存储当前任务的依赖
    @TaskLocal static var _current: DependencyValues?

    /// 获取当前依赖容器
    public static var current: DependencyValues {
        _current ?? .makeDefault()
    }
}

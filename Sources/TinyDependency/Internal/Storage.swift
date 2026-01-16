import Foundation

/// 内部存储，使用类型擦除来存储不同类型的依赖值
final class DependencyStorage: @unchecked Sendable {
    // 注意：这里使用 any Sendable 实现类型擦除
    // DependencyKey 协议在父级模块中定义
    private var storage: [ObjectIdentifier: any Sendable] = [:]
    private let lock = NSLock()

    /// 获取指定键的值
    func get<Key>(_ key: Key.Type) -> (any Sendable)? {
        lock.lock()
        defer { lock.unlock() }
        return storage[ObjectIdentifier(key)]
    }

    /// 设置指定键的值
    func set<Key>(_ value: any Sendable, for key: Key.Type) {
        lock.lock()
        defer { lock.unlock() }
        storage[ObjectIdentifier(key)] = value
    }

    /// 创建副本，用于 withDependencies
    func copy() -> DependencyStorage {
        lock.lock()
        defer { lock.unlock() }
        let newStorage = DependencyStorage()
        newStorage.storage = storage
        return newStorage
    }
}

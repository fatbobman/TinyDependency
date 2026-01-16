# TinyDependency

[![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org)
[![Platforms](https://img.shields.io/badge/Platforms-iOS%20|%20macOS%20|%20tvOS%20|%20watchOS%20|%20visionOS-blue.svg)](https://swift.org)
[![Swift Package Manager](https://img.shields.io/badge/SPM-compatible-brightgreen.svg)](https://swift.org/package-manager)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

[English](README.md)

一个轻量级的 Swift 依赖注入库，专为 SwiftUI 项目中的非视图场景设计。

## 特性

- ✅ **熟悉的 API**: 类似 SwiftUI.Environment 的声明式语法
- ✅ **并发安全**: 强制 Sendable 约束,基于 @TaskLocal 实现
- ✅ **三种作用域**: `default`、`test`、`preview` 自动切换
- ✅ **轻量级**: 零第三方依赖,纯 Swift 实现
- ✅ **Swift 6**: 完全支持严格并发检查

## 系统要求

- Swift 6.0+
- iOS 16+ / macOS 13+ / tvOS 16+ / watchOS 9+ / visionOS 1+

## 安装

### Swift Package Manager

在 `Package.swift` 中添加:

```swift
dependencies: [
    .package(url: "https://github.com/fatbobman/TinyDependency.git", from: "0.1.0")
]
```

或在 Xcode 中通过 File → Add Package Dependencies 添加。

## 使用方法

### 1. 定义依赖协议

```swift
protocol Logger: Sendable {
    func log(_ message: String)
}

struct ProductionLogger: Logger {
    func log(_ message: String) {
        print("[\(Date())] \(message)")
    }
}

struct MockLogger: Logger {
    func log(_ message: String) {
        // 静默或记录到内存
    }
}
```

### 2. 创建依赖键

```swift
import TinyDependency

private struct LoggerKey: DependencyKey {
    static let defaultValue: Logger = ProductionLogger()
    static let testValue: Logger = MockLogger()
    static let previewValue: Logger = MockLogger()
}

extension DependencyValues {
    var logger: Logger {
        get { self[LoggerKey.self] }
        set { self[LoggerKey.self] = newValue }
    }
}
```

### 3. 使用依赖

```swift
class UserService {
    @Dependency(\.logger) var logger

    func createUser(name: String) async {
        logger.log("Creating user: \(name)")
        // 业务逻辑...
    }
}
```

### 4. 测试时覆盖依赖

```swift
import Testing
@testable import YourApp

@Test
func testUserService() async {
    let customLogger = CustomMockLogger()

    await withDependencies {
        $0.logger = customLogger
    } operation: {
        let service = UserService()
        await service.createUser(name: "Alice")

        #expect(customLogger.messages.contains("Creating user: Alice"))
    }
}
```

## 作用域说明

TinyDependency 根据运行环境自动选择合适的默认值:

| 环境 | 使用的值 |
|------|---------|
| Production (Release) | `defaultValue` |
| Development (Debug) | `testValue` |
| Xcode Preview | `previewValue` |

你可以在 `DependencyKey` 中省略 `testValue` 和 `previewValue`,它们会自动回退到 `defaultValue`:

```swift
private struct LoggerKey: DependencyKey {
    static let defaultValue: Logger = ProductionLogger()
    // testValue 和 previewValue 自动使用 defaultValue
}
```

## 高级用法

### 嵌套作用域

```swift
withDependencies {
    $0.logger = Logger1()
} operation: {
    // 使用 Logger1

    withDependencies {
        $0.logger = Logger2()
    } operation: {
        // 使用 Logger2
    }

    // 恢复为 Logger1
}
```

### 异步支持

```swift
await withDependencies {
    $0.database = MockDatabase()
} operation: {
    await someAsyncWork()
}
```

### 并发安全

基于 `@TaskLocal`,依赖在任务之间自动隔离:

```swift
await withTaskGroup(of: Void.self) { group in
    group.addTask {
        await withDependencies {
            $0.logger = Logger1()
        } operation: {
            // 任务 1 使用 Logger1
        }
    }

    group.addTask {
        await withDependencies {
            $0.logger = Logger2()
        } operation: {
            // 任务 2 使用 Logger2,不受任务 1 影响
        }
    }
}
```

## 设计理念

### 为什么需要 Sendable?

强制 Sendable 约束简化了并发安全设计:
- 不需要复杂的锁机制
- 编译时保证线程安全
- 与 Swift 6 严格并发模型完美配合

### 与 Pointfree Dependencies 的区别

| 特性 | TinyDependency | Pointfree Dependencies |
|------|----------------|------------------------|
| 复杂度 | 轻量级,约 200 行代码 | 重量级,功能完整 |
| Sendable | 强制要求 | 可选 |
| 作用域 | 3 种固定作用域 | 灵活的作用域系统 |
| 学习曲线 | 低,类似 Environment | 中等 |
| 目标场景 | 视图外使用 | 全场景 |

TinyDependency 专注于简单场景,如果你需要更强大的功能(如依赖追踪、自动 mock 生成等),建议使用 [Pointfree Dependencies](https://github.com/pointfreeco/swift-dependencies)。

## 示例项目

查看 `Tests/TinyDependencyTests` 目录了解完整的使用示例。

## License

MIT License

## 作者

[Fatbobman](https://fatbobman.com)

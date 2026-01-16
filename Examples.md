# TinyDependency 使用示例

## 示例 1: Logger 依赖

### 定义协议和实现

```swift
import TinyDependency

// 1. 定义协议
protocol Logger: Sendable {
    func log(_ message: String)
    func error(_ message: String)
}

// 2. 生产环境实现
struct ConsoleLogger: Logger {
    func log(_ message: String) {
        print("ℹ️ [\(Date())] \(message)")
    }

    func error(_ message: String) {
        print("❌ [\(Date())] ERROR: \(message)")
    }
}

// 3. 测试环境实现
actor InMemoryLogger: Logger {
    private(set) var messages: [String] = []

    func log(_ message: String) {
        messages.append(message)
    }

    func error(_ message: String) {
        messages.append("ERROR: \(message)")
    }
}
```

### 注册依赖

```swift
private struct LoggerKey: DependencyKey {
    static let defaultValue: Logger = ConsoleLogger()
    static let testValue: Logger = InMemoryLogger()
}

extension DependencyValues {
    var logger: Logger {
        get { self[LoggerKey.self] }
        set { self[LoggerKey.self] = newValue }
    }
}
```

### 使用依赖

```swift
class UserService {
    @Dependency(\.logger) var logger

    func createUser(name: String) async throws {
        logger.log("Creating user: \(name)")

        // 业务逻辑
        try await saveToDatabase(name)

        logger.log("User created successfully")
    }

    private func saveToDatabase(_ name: String) async throws {
        // 数据库操作
    }
}
```

### 测试

```swift
@Test
func testUserService() async throws {
    let testLogger = InMemoryLogger()

    await withDependencies {
        $0.logger = testLogger
    } operation: {
        let service = UserService()
        try await service.createUser(name: "Alice")

        let messages = await testLogger.messages
        #expect(messages.contains { $0.contains("Creating user: Alice") })
        #expect(messages.contains { $0.contains("successfully") })
    }
}
```

## 示例 2: Database 依赖

```swift
protocol Database: Sendable {
    func query<T: Sendable>(_ sql: String) async throws -> [T]
    func execute(_ sql: String) async throws
}

struct SQLiteDatabase: Database {
    func query<T: Sendable>(_ sql: String) async throws -> [T] {
        // 真实数据库查询
        []
    }

    func execute(_ sql: String) async throws {
        // 真实数据库执行
    }
}

actor InMemoryDatabase: Database {
    private var data: [String: [Any]] = [:]

    func query<T: Sendable>(_ sql: String) async throws -> [T] {
        // 从内存返回数据
        []
    }

    func execute(_ sql: String) async throws {
        // 更新内存数据
    }
}

private struct DatabaseKey: DependencyKey {
    static let defaultValue: Database = SQLiteDatabase()
    static let testValue: Database = InMemoryDatabase()
}

extension DependencyValues {
    var database: Database {
        get { self[DatabaseKey.self] }
        set { self[DatabaseKey.self] = newValue }
    }
}
```

## 示例 3: 多个依赖组合

```swift
class TodoRepository {
    @Dependency(\.database) var database
    @Dependency(\.logger) var logger

    func fetchAll() async throws -> [Todo] {
        logger.log("Fetching all todos")

        let todos: [Todo] = try await database.query("SELECT * FROM todos")

        logger.log("Fetched \(todos.count) todos")
        return todos
    }

    func save(_ todo: Todo) async throws {
        logger.log("Saving todo: \(todo.title)")

        try await database.execute("INSERT INTO todos ...")

        logger.log("Todo saved successfully")
    }
}
```

## 示例 4: API Client

```swift
protocol APIClient: Sendable {
    func request<T: Decodable>(_ endpoint: String) async throws -> T
}

struct ProductionAPIClient: APIClient {
    func request<T: Decodable>(_ endpoint: String) async throws -> T {
        let url = URL(string: "https://api.example.com\(endpoint)")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(T.self, from: data)
    }
}

actor MockAPIClient: APIClient {
    var responses: [String: Any] = [:]

    func request<T: Decodable>(_ endpoint: String) async throws -> T {
        guard let data = responses[endpoint] as? T else {
            throw URLError(.badServerResponse)
        }
        return data
    }

    func setResponse<T>(_ response: T, for endpoint: String) {
        responses[endpoint] = response
    }
}

private struct APIClientKey: DependencyKey {
    static let defaultValue: APIClient = ProductionAPIClient()
    static let testValue: APIClient = MockAPIClient()
}

extension DependencyValues {
    var apiClient: APIClient {
        get { self[APIClientKey.self] }
        set { self[APIClientKey.self] = newValue }
    }
}
```

## 示例 5: 在 SwiftUI View Model 中使用

```swift
@Observable
class TodoViewModel {
    @Dependency(\.database) var database
    @Dependency(\.logger) var logger

    private(set) var todos: [Todo] = []
    private(set) var isLoading = false

    func loadTodos() async {
        isLoading = true
        logger.log("Loading todos")

        do {
            todos = try await database.query("SELECT * FROM todos")
            logger.log("Loaded \(todos.count) todos")
        } catch {
            logger.error("Failed to load todos: \(error)")
        }

        isLoading = false
    }
}
```

## 示例 6: 条件依赖

```swift
// 根据环境变量选择不同的实现
private struct APIClientKey: DependencyKey {
    static var defaultValue: APIClient {
        if ProcessInfo.processInfo.environment["USE_MOCK_API"] == "1" {
            return MockAPIClient()
        }
        return ProductionAPIClient()
    }

    static let testValue: APIClient = MockAPIClient()
}
```

## 最佳实践

### 1. 使用协议而非具体类型

```swift
// ✅ 好
protocol Storage: Sendable {
    func save(_ data: Data)
}

// ❌ 不好
struct FileStorage {
    func save(_ data: Data)
}
```

### 2. 保持依赖的 Sendable 性

```swift
// ✅ 好 - 使用 actor
actor UserCache: Sendable {
    private var cache: [String: User] = [:]

    func get(_ id: String) -> User? {
        cache[id]
    }
}

// ❌ 不好 - class 不是 Sendable
class UserCache {
    var cache: [String: User] = [:]
}
```

### 3. 测试时使用 Actor

```swift
actor MockLogger: Logger, Sendable {
    private(set) var messages: [String] = []

    func log(_ message: String) {
        messages.append(message)
    }
}
```

### 4. 简化测试值定义

```swift
// 如果 test 和 preview 使用相同的值,可以省略
private struct LoggerKey: DependencyKey {
    static let defaultValue: Logger = ProductionLogger()
    // testValue 和 previewValue 自动使用 defaultValue
}
```

import Testing

@testable import TinyDependency

// MARK: - 测试用的协议和实现

protocol Logger: Sendable {
  func log(_ message: String)
}

struct ProductionLogger: Logger {
  func log(_ message: String) {
    print("[Production] \(message)")
  }
}

struct TestLogger: Logger {
  func log(_ message: String) {
    print("[Test] \(message)")
  }
}

struct MockLogger: Logger {
  func log(_ message: String) {
    print("[Mock] \(message)")
  }
}

// MARK: - 依赖键定义

private struct LoggerKey: DependencyKey {
  static let defaultValue: Logger = ProductionLogger()
  static let testValue: Logger = TestLogger()
  static let previewValue: Logger = TestLogger()
}

extension DependencyValues {
  var logger: Logger {
    get { self[LoggerKey.self] }
    set { self[LoggerKey.self] = newValue }
  }
}

// MARK: - 测试

@Suite("TinyDependency 基础测试")
struct TinyDependencyTests {

  @Test("依赖键默认值")
  func testDefaultValue() {
    let logger = DependencyValues.current.logger
    #expect(logger is TestLogger)  // 在测试环境中应该使用 testValue
  }

  @Test("withDependencies 临时覆盖")
  func testWithDependencies() {
    // 默认是 TestLogger
    let defaultLogger = DependencyValues.current.logger
    #expect(defaultLogger is TestLogger)

    // 临时覆盖
    withDependencies {
      $0.logger = MockLogger()
    } operation: {
      let mockLogger = DependencyValues.current.logger
      #expect(mockLogger is MockLogger)
    }

    // 作用域外恢复
    let restoredLogger = DependencyValues.current.logger
    #expect(restoredLogger is TestLogger)
  }

  @Test("PropertyWrapper 访问")
  func testPropertyWrapper() {
    class Service {
      @Dependency(\.logger) var logger

      func getLoggerType() -> String {
        String(describing: type(of: logger))
      }
    }

    let service = Service()
    #expect(service.getLoggerType().contains("TestLogger"))

    withDependencies {
      $0.logger = MockLogger()
    } operation: {
      let mockService = Service()
      #expect(mockService.getLoggerType().contains("MockLogger"))
    }
  }

  @Test("并发安全测试")
  func testConcurrency() async {
    await withDependencies {
      $0.logger = MockLogger()
    } operation: {
      await withTaskGroup(of: Bool.self) { group in
        for _ in 0..<10 {
          group.addTask {
            let logger = DependencyValues.current.logger
            return logger is MockLogger
          }
        }

        for await result in group {
          #expect(result == true)
        }
      }
    }
  }

  @Test("嵌套作用域")
  func testNestedScopes() {
    withDependencies {
      $0.logger = ProductionLogger()
    } operation: {
      let outer = DependencyValues.current.logger
      #expect(outer is ProductionLogger)

      withDependencies {
        $0.logger = MockLogger()
      } operation: {
        let inner = DependencyValues.current.logger
        #expect(inner is MockLogger)
      }

      // 内层作用域不影响外层
      let restored = DependencyValues.current.logger
      #expect(restored is ProductionLogger)
    }
  }
}

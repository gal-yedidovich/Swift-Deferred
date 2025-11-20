// The Swift Programming Language
// https://docs.swift.org/swift-book

actor Deferred<Value: Sendable> {
  private var continuation: CheckedContinuation<Value, Error>? = nil

  nonisolated func complete(value: Value) {
    Task {
      await continuation?.resume(returning: value)
    }
  }

  var value: Value {
    get async throws {
      try await withCheckedThrowingContinuation { continuation in
        self.continuation = continuation
      }
    }
  }
}

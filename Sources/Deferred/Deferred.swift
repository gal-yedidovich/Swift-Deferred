// The Swift Programming Language
// https://docs.swift.org/swift-book

actor Deferred<Value: Sendable> {
  private var result: Result<Value, Error>? = nil
  private var continuations: [CheckedContinuation<Value, Error>] = []

  nonisolated func complete(value: Value) {
    Task {
      await resolve(.success(value))
    }
  }

  var value: Value {
    get async throws {
      if let result {
        return try result.get()
      }

      return try await withCheckedThrowingContinuation { continuation in
        self.continuations.append(continuation)
      }
    }
  }

  private func resolve(_ result: Result<Value, Error>) {
    self.result = result
    let copy = continuations

    for continuation in copy {
      continuation.resume(with: result)
    }
  }
}

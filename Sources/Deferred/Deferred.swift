actor Deferred<Value: Sendable> {
  private var result: Result<Value, Error>? = nil
  private var continuations: [CheckedContinuation<Value, Error>] = []

  nonisolated func complete(value: Value) {
    complete(with: .success(value))
  }

  nonisolated func complete(error: Error) {
    complete(with: .failure(error))
  }

  nonisolated func complete(with result: Result<Value, Error>) {
    Task { @DeferredExecutor in
      await resolve(result)
    }
  }

  var value: Value {
    get async throws {
      if let result {
        return try result.get()
      }

      try Task.checkCancellation()
      return try await withCheckedThrowingContinuation { continuation in
        self.continuations.append(continuation)
      }
    }
  }

  private func resolve(_ result: Result<Value, Error>) {
    guard self.result == nil else { return }

    self.result = result
    let copy = continuations
    continuations.removeAll(keepingCapacity: true)

    for continuation in copy {
      continuation.resume(with: result)
    }
  }
}

@globalActor
actor DeferredExecutor {
  static let shared = DeferredExecutor()
}

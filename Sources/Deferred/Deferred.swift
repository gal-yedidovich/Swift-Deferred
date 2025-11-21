public actor Deferred<Value: Sendable> {
  private var result: Result<Value, Error>? = nil
  private var continuations: [CheckedContinuation<Value, Error>] = []

  public init() {}

  public nonisolated func complete(value: Value) {
    complete(with: .success(value))
  }

  public nonisolated func complete(error: Error) {
    complete(with: .failure(error))
  }

  public nonisolated func complete(with result: Result<Value, Error>) {
    Task { @DeferredExecutor in
      await resolve(result)
    }
  }

  public var value: Value {
    get async throws {
      try Task.checkCancellation()

      if let result {
        return try result.get()
      }

      return try await withCheckedThrowingContinuation { continuation in
        self.continuations.append(continuation)
      }
    }
  }

  private func resolve(_ result: Result<Value, Error>) {
    if Task.isCancelled || self.result != nil { return }

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

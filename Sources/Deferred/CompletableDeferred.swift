//
//  CompletableDeferred.swift
//  Swift-Deferred
//
//  Created by Gal Yedidovich on 23/11/2025.
//

import Foundation

/// An actor that represents a single value that will be completed exactly once in the future.
///
/// `CompletableDeferred` provides a way to create a deferred value that can be completed
/// manually by calling one of its completion methods. Multiple tasks can await the same
/// value, and they will all receive the result once it's completed.
///
/// Once completed (either with a value or an error), subsequent completion attempts are
/// ignored, and the original result is preserved. All tasks awaiting the value will receive
/// the same result.
///
/// ## Completing a Deferred
///
/// You can complete a deferred in three ways:
///
/// ```swift
/// let deferred = CompletableDeferred<String>()
///
/// // Complete with a value
/// deferred.complete(value: "Success")
///
/// // Complete with an error
/// deferred.complete(error: MyError.failed)
///
/// // Complete with a Result
/// deferred.complete(with: .success("Done"))
/// ```
///
/// ## Awaiting Multiple Times
///
/// Multiple tasks can await the same deferred value. Once completed, all suspended tasks
/// receive the result:
///
/// ```swift
/// let deferred = CompletableDeferred<Int>()
///
/// Task {
///     let value = try await deferred.value
///     print("Task 1: \(value)")
/// }
///
/// Task {
///     let value = try await deferred.value
///     print("Task 2: \(value)")
/// }
///
/// // Both tasks will receive the value
/// deferred.complete(value: 42)
/// ```
///
/// ## Single Completion Guarantee
///
/// Once a deferred is completed, it cannot be changed. Subsequent completion attempts
/// have no effect:
///
/// ```swift
/// let deferred = CompletableDeferred<String>()
/// deferred.complete(value: "First")
/// deferred.complete(value: "Second") // Ignored
///
/// let result = try await deferred.value // Returns "First"
/// ```
///
/// ## Cancellation
///
/// When a task awaiting the deferred value is cancelled, it throws `CancellationError`.
/// Other tasks awaiting the same deferred are unaffected:
///
/// ```swift
/// let deferred = CompletableDeferred<String>()
///
/// let task1 = Task {
///     try await deferred.value
/// }
///
/// let task2 = Task {
///     try await deferred.value
/// }
///
/// task1.cancel() // Only task1 throws CancellationError
/// deferred.complete(value: "Done") // task2 receives this value
/// ```
///
/// ## Thread Safety
///
/// `CompletableDeferred` is an actor, ensuring thread-safe access to its state. Completion
/// methods are `nonisolated` and can be called from any context without `await`.
///
/// - SeeAlso: ``Deferred``
public actor CompletableDeferred<Value: Sendable> {
  private var result: Result<Value, Error>? = nil
  private var continuations: [UUID: CheckedContinuation<Value, Error>] = [:]

  /// Creates a new uncompleted deferred.
  ///
  /// The deferred starts in an incomplete state. Tasks that access its `value` property
  /// will suspend until the deferred is completed via one of the completion methods.
  public init() {}

  /// Completes the deferred with a successful value.
  ///
  /// After calling this method, all tasks awaiting the deferred's value will receive
  /// the provided value. If the deferred has already been completed, this call has no effect.
  ///
  /// This method can be called from any context without `await`.
  ///
  /// - Parameter value: The value to complete the deferred with.
  public nonisolated func complete(value: Value) {
    complete(with: .success(value))
  }

  /// Completes the deferred with an error.
  ///
  /// After calling this method, all tasks awaiting the deferred's value will throw
  /// the provided error. If the deferred has already been completed, this call has no effect.
  ///
  /// This method can be called from any context without `await`.
  ///
  /// - Parameter error: The error to complete the deferred with.
  public nonisolated func complete(error: Error) {
    complete(with: .failure(error))
  }

  /// Completes the deferred with a result.
  ///
  /// After calling this method, all tasks awaiting the deferred's value will receive
  /// the provided result (either a value or an error). If the deferred has already been
  /// completed, this call has no effect.
  ///
  /// This method can be called from any context without `await`.
  ///
  /// - Parameter result: The result to complete the deferred with.
  public nonisolated func complete(with result: Result<Value, Error>) {
    Task { @DeferredExecutor in
      await resolve(result)
    }
  }

  private func resolve(_ result: Result<Value, Error>) {
    if Task.isCancelled || self.result != nil { return }

    self.result = result
    let copy = continuations
    continuations.removeAll(keepingCapacity: true)

    for (_, continuation) in copy {
      continuation.resume(with: result)
    }
  }
}

extension CompletableDeferred: Deferred {
  /// The value that this deferred will provide once completed.
  ///
  /// Accessing this property suspends the current task until the deferred is completed
  /// via one of the completion methods. If the current task is cancelled while waiting,
  /// this property throws `CancellationError`.
  ///
  /// If the deferred has already been completed when this property is accessed, the result
  /// is returned immediately without suspending.
  ///
  /// Multiple tasks can access this property concurrently, and they will all receive the
  /// same result once the deferred is completed.
  ///
  /// - Throws: `CancellationError` if the task is cancelled while waiting, or the error
  ///   provided to `complete(error:)` if the deferred failed.
  /// - Returns: The value provided to `complete(value:)` once the deferred is completed.
  public var value: Value {
    get async throws {
      try Task.checkCancellation()

      if let result {
        return try result.get()
      }

      let id = UUID()
      return try await withTaskCancellationHandler {
        return try await withCheckedThrowingContinuation { continuation in
          self.continuations[id] = continuation
        }
      } onCancel: {
        Task { @DeferredExecutor in await cancel(id: id) }
      }
    }
  }

  private func cancel(id: UUID) {
    guard let continuation = self.continuations.removeValue(forKey: id) else {
      return
    }

    continuation.resume(throwing: CancellationError())
  }
}

/// A global actor that serializes execution of deferred completion operations.
///
/// This actor ensures that completion operations are processed serially, preventing
/// race conditions when completing a deferred from multiple contexts.
@globalActor
actor DeferredExecutor {
  static let shared = DeferredExecutor()
}

//
//  WithTimeout.swift
//  Swift-Deferred
//
//  Created by Gal Yedidovich on 29/11/2025.
//

import Foundation

/// Executes an asynchronous operation with a time limit.
///
/// Use this function when you need to ensure that an asynchronous operation completes
/// within a specified time period. If the operation doesn't complete before the timeout
/// expires, the function throws a ``TimeoutError``.
///
/// ## Basic Usage
///
/// ```swift
/// do {
///     let result = try await withTimeout(5.0) {
///         try await fetchDataFromServer()
///     }
///     print("Received: \(result)")
/// } catch is TimeoutError {
///     print("Operation timed out")
/// } catch {
///     print("Operation failed: \(error)")
/// }
/// ```
///
/// ## Timeout Behavior
///
/// When the timeout expires before the operation completes:
/// - The operation is automatically cancelled
/// - A ``TimeoutError`` is thrown
///
/// ```swift
/// try await withTimeout(1.0) {
///     // This will timeout after 1 second
///     try await Task.sleep(for: .seconds(10))
/// }
/// // Throws TimeoutError(timeout: 1.0)
/// ```
///
/// ## Successful Completion
///
/// If the operation completes before the timeout, its result is returned and the
/// timeout task is automatically cancelled:
///
/// ```swift
/// let result = try await withTimeout(10.0) {
///     return "Success"
/// }
/// print(result) // "Success"
/// ```
///
/// ## Cancellation
///
/// If the parent task is cancelled, the operation throws `CancellationError` immediately,
/// regardless of the timeout:
///
/// ```swift
/// let task = Task {
///     try await withTimeout(60.0) {
///         try await longRunningOperation()
///     }
/// }
///
/// task.cancel() // Throws CancellationError, not TimeoutError
/// ```
///
/// ## Error Handling
///
/// The function can throw three types of errors:
/// - ``TimeoutError``: The operation exceeded the time limit
/// - `CancellationError`: The task was cancelled
/// - Any error thrown by the operation itself
///
/// ```swift
/// do {
///     try await withTimeout(5.0) {
///         throw MyError.somethingWentWrong
///     }
/// } catch let error as MyError {
///     // Handle operation error
/// } catch is TimeoutError {
///     // Handle timeout
/// }
/// ```
///
/// - Parameters:
///   - timeout: The maximum time interval, in seconds, to wait for the operation to complete.
///   - operation: An asynchronous closure that performs the operation.
///
/// - Returns: The value returned by the operation.
///
/// - Throws: ``TimeoutError`` if the timeout expires, `CancellationError` if the task is
///   cancelled, or any error thrown by the operation.
///
/// - SeeAlso: ``TimeoutError``
public func withTimeout<T: Sendable>(
  _ timeout: TimeInterval,
  operation: @escaping @Sendable () async throws -> T
) async throws -> T {
  return try await withThrowingTaskGroup { group in
    group.addTask(name: "Operation", operation: operation)
    group.addTask(name: "Timeout") {
      try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
      throw TimeoutError(timeout: timeout)
    }

    defer { group.cancelAll() }
    return try await group.next()!
  }
}

/// An error thrown when an operation exceeds its time limit.
///
/// This error is thrown by ``withTimeout(_:operation:)`` when the specified timeout
/// interval elapses before the operation completes.
///
/// The error includes the timeout duration that was exceeded, which can be useful
/// for logging and debugging purposes.
///
/// ## Example
///
/// ```swift
/// do {
///     try await withTimeout(2.0) {
///         try await Task.sleep(for: .seconds(10))
///     }
/// } catch let error as TimeoutError {
///     print("Timed out after \(error.timeout) seconds")
/// }
/// ```
///
/// - SeeAlso: ``withTimeout(_:operation:)``
public struct TimeoutError: LocalizedError, Equatable {
  /// The timeout interval, in seconds, that was exceeded.
  ///
  /// This value matches the timeout parameter passed to ``withTimeout(_:operation:)``.
  let timeout: TimeInterval

  /// Creates a timeout error with the specified duration.
  ///
  /// - Parameter timeout: The timeout interval, in seconds, that was exceeded.
  public init(timeout: TimeInterval) {
    self.timeout = timeout
  }
}

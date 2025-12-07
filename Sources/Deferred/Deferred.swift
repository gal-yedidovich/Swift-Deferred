//
//  Deferred.swift
//  Swift-Deferred
//
//  Created by Gal Yedidovich on 23/11/2025.
//

import Foundation

/// A protocol that represents a value that will be available asynchronously in the future.
///
/// A deferred value suspends when you access its `value` property until the value becomes
/// available. Use this protocol when you need to represent a computation or operation that
/// will complete at some point in the future and make its result available to one or more
/// concurrent tasks.
///
/// Types conforming to `Deferred` must provide a `value` property that can be accessed
/// asynchronously. The property suspends execution until the value is ready and may throw
/// an error if the operation fails.
///
/// ## Example Usage
///
/// ```swift
/// func fetchUserData(deferred: some Deferred<User>) async throws {
///     let user = try await deferred.value
///     print("Received user: \(user.name)")
/// }
/// ```
///
/// ## Cancellation
///
/// Implementations should support task cancellation by checking `Task.isCancelled` and
/// throwing `CancellationError` when appropriate.
///
/// ## Concurrency
///
/// The `value` property is accessed asynchronously and may be called from multiple
/// concurrent contexts. Implementations must be thread-safe and ensure that all
/// suspended tasks receive the same result once it becomes available.
///
/// - SeeAlso: ``CompletableDeferred``
public protocol Deferred {
  /// The type of value that will be provided by this deferred.
  associatedtype Value: Sendable

  /// The value that this deferred will eventually provide.
  ///
  /// Accessing this property suspends the current task until the value becomes available.
  /// If the deferred fails, this property throws an error.
  ///
  /// - Throws: An error if the operation fails, or `CancellationError` if the task is cancelled.
  /// - Returns: The deferred value once it becomes available.
  var value: Value { get async throws }
}

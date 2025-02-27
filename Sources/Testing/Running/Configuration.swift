//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2023 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for Swift project authors
//

/// A type containing settings for preparing and running tests.
@_spi(ExperimentalTestRunning)
public struct Configuration: Sendable {
  /// Initialize an instance of this type representing the default
  /// configuration.
  public init() {}

  // MARK: - Parallelization

  /// Whether or not to parallelize the execution of tests and test cases.
  public var isParallelizationEnabled = true

  /// A type describing whether or not, and how, to iterate a test plan
  /// repeatedly.
  ///
  /// When a ``Runner`` is run, it will run all tests in its corresponding
  /// ``Runner/Plan`` according to the policy described by its
  /// ``Configuration/repetitionPolicy-swift.property`` property. For instance,
  /// if that property is set to:
  ///
  /// ```swift
  /// .repeating(.untilIssueRecorded, count: 10)
  /// ```
  ///
  /// The entire test plan will be run repeatedly, up to 10 times. If an issue
  /// is recorded, the current iteration will complete, but no further
  /// iterations will be attempted.
  ///
  /// If the value of an instance's ``maximumIterationCount`` property is `1`,
  /// the value of its ``continuationCondition-swift.property`` property has no
  /// effect.
  public struct RepetitionPolicy: Sendable {
    /// An enumeration describing the conditions under which test iterations
    /// should continue.
    public enum ContinuationCondition: Sendable {
      /// The test plan should continue iterating until an unknown issue is
      /// recorded.
      ///
      /// When this continuation condition is used and an issue is recorded, the
      /// current iteration will complete, but no further iterations will be
      /// attempted.
      case untilIssueRecorded

      /// The test plan should continue iterating until an iteration completes
      /// with no unknown issues recorded.
      case whileIssueRecorded
    }

    /// The conditions under which test iterations should continue.
    ///
    /// If the value of this property is `nil`, a test plan will be run
    /// ``count`` times regardless of whether or not issues are encountered
    /// while running.
    public var continuationCondition: ContinuationCondition?

    /// The maximum number of times the test run should iterate.
    ///
    /// - Precondition: The value of this property must be greater than or equal
    ///   to `1`.
    public var maximumIterationCount: Int {
      willSet {
        precondition(newValue >= 1, "Test runs must iterate at least once.")
      }
    }

    /// Create an instance of this type.
    ///
    /// - Parameters:
    ///   - continuationCondition: The conditions under which test iterations
    ///     should continue. If `nil`, the iterations should continue
    ///     unconditionally `count` times.
    ///   - count: The maximum number of times the test run should iterate.
    public static func repeating(_ continuationCondition: ContinuationCondition? = nil, maximumIterationCount: Int) -> Self {
      Self(continuationCondition: continuationCondition, maximumIterationCount: maximumIterationCount)
    }

    /// An instance of this type representing a single iteration.
    public static var once: Self {
      repeating(maximumIterationCount: 1)
    }
  }

  /// Whether or not, and how, to iterate the test plan repeatedly.
  ///
  /// By default, the value of this property allows for a single iteration.
  public var repetitionPolicy: RepetitionPolicy = .once

  // MARK: - Main actor isolation

#if !SWT_NO_GLOBAL_ACTORS
  /// Whether or not synchronous test functions need to run on the main actor.
  ///
  /// This property is available on platforms where UI testing is implemented.
  public var isMainActorIsolationEnforced = false
#endif

  // MARK: - Time limits

  /// Storage for the ``defaultTestTimeLimit`` property.
  private var _defaultTestTimeLimit: (any Sendable)?

  /// The default amount of time a test may run for before timing out if it does
  /// not have an instance of ``TimeLimitTrait`` applied to it.
  ///
  /// If the value of this property is `nil`, individual test functions may run
  /// up to the limit specified by ``maximumTestTimeLimit``.
  ///
  /// To determine the actual time limit that applies to an instance of
  /// ``Test`` at runtime, use ``Test/adjustedTimeLimit(configuration:)``.
  @available(_clockAPI, *)
  public var defaultTestTimeLimit: Duration? {
    get {
      _defaultTestTimeLimit as? Duration
    }
    set {
      _defaultTestTimeLimit = newValue
    }
  }

  /// Storage for the ``maximumTestTimeLimit`` property.
  private var _maximumTestTimeLimit: (any Sendable)?

  /// The maximum amount of time a test may run for before timing out,
  /// regardless of the value of ``defaultTestTimeLimit`` or individual
  /// instances of ``TimeLimitTrait`` applied to it.
  ///
  /// If the value of this property is `nil`, individual test functions may run
  /// indefinitely.
  ///
  /// To determine the actual time limit that applies to an instance of
  /// ``Test`` at runtime, use ``Test/adjustedTimeLimit(configuration:)``.
  @available(_clockAPI, *)
  public var maximumTestTimeLimit: Duration? {
    get {
      _maximumTestTimeLimit as? Duration
    }
    set {
      _maximumTestTimeLimit = newValue
    }
  }

  /// Storage for the ``testTimeLimitGranularity`` property.
  private var _testTimeLimitGranularity: (any Sendable)?

  /// The granularity to enforce on test time limits.
  ///
  /// By default, test time limit granularity is limited to intervals of one
  /// minute (60 seconds.) If finer or coarser granularity is required, the
  /// value of this property can be adjusted.
  @available(_clockAPI, *)
  public var testTimeLimitGranularity: Duration {
    get {
      (_testTimeLimitGranularity as? Duration) ?? .seconds(60)
    }
    set {
      _testTimeLimitGranularity = newValue
    }
  }

  // MARK: - Event handling

  /// Whether or not events of the kind
  /// ``Event/Kind-swift.enum/expectationChecked(_:)`` should be delivered to
  /// this configuration's ``eventHandler`` closure.
  ///
  /// By default, events of this kind are not delivered to event handlers
  /// because they occur frequently in a typical test run and can generate
  /// significant backpressure on the event handler.
  @_spi(ExperimentalEventHandling)
  public var deliverExpectationCheckedEvents = false

  /// The event handler to which events should be passed when they occur.
  @_spi(ExperimentalEventHandling)
  public var eventHandler: Event.Handler = { _, _ in }

  // MARK: - Test selection

  /// A function that handles filtering tests.
  ///
  /// - Parameters:
  ///   - test: An test that needs to be filtered.
  ///
  /// - Returns: A Boolean value representing if the test satisfied the filter.
  public typealias TestFilter = @Sendable (_ test: Test) -> Bool

  /// Storage for ``testFilter-swift.property``.
  private var _testFilter: TestFilter = { !$0.isHidden }

  /// The test filter to which tests should be filtered when run.
  public var testFilter: TestFilter {
    get {
      _testFilter
    }
    set {
      // By default, the test filter should always filter out hidden tests. This
      // is the appropriate behavior for external clients of this SPI. If the
      // testing library needs to enable hidden tests in its own test targets,
      // it can instead use `uncheckedTestFilter`.
      _testFilter = { test in
        !test.isHidden && newValue(test)
      }
    }
  }

  /// The test filter to which tests should be filtered when run.
  ///
  /// Unlike ``testFilter-swift.property``, this property does not impose any
  /// checks for hidden tests. It is used by the testing library to run hidden
  /// tests; other callers should always use ``testFilter-swift.property``.
  var uncheckedTestFilter: TestFilter {
    get {
      _testFilter
    }
    set {
      _testFilter = newValue
    }
  }

  // MARK: - Test case selection

  /// A function that handles filtering test cases.
  ///
  /// - Parameters:
  ///   - testCase: The test case to be filtered.
  ///   - test: The test which `testCase` is associated with.
  ///
  /// - Returns: A Boolean value representing if the test case satisfied the
  ///   filter.
  public typealias TestCaseFilter = @Sendable (_ testCase: Test.Case, _ test: Test) -> Bool

  /// The test case filter to which test cases should be filtered when run.
  public var testCaseFilter: TestCaseFilter = { _, _ in true }
}

// MARK: - Test filter factory functions

/// Make a test filter that filters tests to those specified by a set of test
/// IDs.
///
/// - Parameters:
///   - selection: A set of test IDs to be filtered.
///
/// - Returns: A test filter that filters tests to those specified by
///   `selection`.
@_spi(ExperimentalTestRunning)
public func makeTestFilter(matching selection: some Collection<Test.ID>) -> Configuration.TestFilter {
  let selection = Test.ID.Selection(testIDs: selection)
  return { selection.contains($0) }
}

/// Make a test filter that excludes certain tests based on their IDs.
///
/// - Parameters:
///   - selection: A set of test IDs to be excluded.
///
/// - Returns: A test filter that excludes tests based on `selection`.
@_spi(ExperimentalTestRunning)
public func makeTestFilter(excluding selection: some Collection<Test.ID>) -> Configuration.TestFilter {
  let selection = Test.ID.Selection(testIDs: selection)
  return { !selection.contains($0, inferAncestors: false) }
}

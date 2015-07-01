//===--- LoggingWrappers.swift ---------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2015 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

public protocol WrapperType {
  typealias Base
  init(_: Base)
  var base: Base {get set}
}

public protocol LoggingType : WrapperType {
  typealias Log : AnyObject
}

extension LoggingType {
  public var log: Log.Type {
    return Log.self
  }
  
  public var selfType: Any.Type {
    return self.dynamicType
  }
}

public class GeneratorLog {
  public static func dispatchTester<G: GeneratorType>(
    g: G
  ) -> LoggingGenerator<LoggingGenerator<G>> {
    return LoggingGenerator(LoggingGenerator(g))
  }
  public static var next = TypeIndexed(0)
}

public struct LoggingGenerator<Base: GeneratorType>
  : GeneratorType, LoggingType {

  typealias Log = GeneratorLog
  
  public init(_ base: Base) {
    self.base = base
  }
  
  public mutating func next() -> Base.Element? {
    ++Log.next[selfType]
    return base.next()
  }
  
  public var base: Base
}

public class SequenceLog {
  public static func dispatchTester<S: SequenceType>(
    s: S
  ) -> LoggingSequence<LoggingSequence<S>> {
    return LoggingSequence(LoggingSequence(s))
  }
  public static var generate = TypeIndexed(0)
  public static var underestimateCount = TypeIndexed(0)
  public static var map = TypeIndexed(0)
  public static var filter = TypeIndexed(0)
  public static var _customContainsEquatableElement = TypeIndexed(0)
  public static var _preprocessingPass = TypeIndexed(0)
  public static var _copyToNativeArrayBuffer = TypeIndexed(0)
  public static var _initializeTo = TypeIndexed(0)
}

public struct LoggingSequence<Base: SequenceType> : SequenceType, LoggingType {

  typealias Log = SequenceLog
  
  public init(_ base: Base) {
    self.base = base
  }
  
  public func generate() -> LoggingGenerator<Base.Generator> {
    ++Log.generate[selfType]
    return LoggingGenerator(base.generate())
  }

  public func underestimateCount() -> Int {
    ++Log.underestimateCount[selfType]
    return base.underestimateCount()
  }

  public func map<T>(
    @noescape transform: (Base.Generator.Element) -> T
  ) -> [T] {
    ++Log.map[selfType]
    return base.map(transform)
  }

  public func filter(
    @noescape includeElement: (Base.Generator.Element) -> Bool
  ) -> [Base.Generator.Element] {
    ++Log.filter[selfType]
    return base.filter(includeElement)
  }
  
  public func _customContainsEquatableElement(
    element: Base.Generator.Element
  ) -> Bool? {
    ++Log._customContainsEquatableElement[selfType]
    return base._customContainsEquatableElement(element)
  }
  
  /// If `self` is multi-pass (i.e., a `CollectionType`), invoke
  /// `preprocess` on `self` and return its result.  Otherwise, return
  /// `nil`.
  public func _preprocessingPass<R>(
    preprocess: (LoggingSequence)->R
  ) -> R? {
    ++Log._preprocessingPass[selfType]
    return base._preprocessingPass { _ in preprocess(self) }
  }

  /// Create a native array buffer containing the elements of `self`,
  /// in the same order.
  public func _copyToNativeArrayBuffer()
    -> _ContiguousArrayBuffer<Base.Generator.Element> {
    ++Log._copyToNativeArrayBuffer[selfType]
    return base._copyToNativeArrayBuffer()
  }

  /// Copy a Sequence into an array.
  public func _initializeTo(ptr: UnsafeMutablePointer<Base.Generator.Element>) {
    ++Log._initializeTo[selfType]
    return base._initializeTo(ptr)
  }
  
  public var base: Base
}

public class CollectionLog : SequenceLog {
  public class func dispatchTester<C : CollectionType>(
    c: C
  ) -> LoggingCollection<LoggingCollection<C>> {
    return LoggingCollection(LoggingCollection(c))
  }
  public static var startIndex = TypeIndexed(0)
  public static var endIndex = TypeIndexed(0)
  public static var subscriptIndex = TypeIndexed(0)
  public static var subscriptRange = TypeIndexed(0)
  public static var isEmpty = TypeIndexed(0)
  public static var count = TypeIndexed(0)
  public static var _customIndexOfEquatableElement = TypeIndexed(0)
  public static var first = TypeIndexed(0)
}

public struct LoggingCollection<Base : CollectionType>
  : CollectionType, LoggingType {

  typealias Log = CollectionLog

  public init(_ base: Base) {
    self.base = base
  }

  public func generate() -> LoggingGenerator<Base.Generator> {
    ++Log.generate[selfType]
    return LoggingGenerator(base.generate())
  }

  public var startIndex: Base.Index {
    ++CollectionLog.startIndex[selfType]
    return base.startIndex
  }

  public var endIndex: Base.Index {
    ++CollectionLog.endIndex[selfType]
    return base.endIndex
  }

  public subscript(position: Base.Index) -> Base.Generator.Element {
    ++CollectionLog.subscriptIndex[selfType]
    return base[position]
  }

  public subscript(bounds: Range<Base.Index>) -> Base.SubSequence {
    ++CollectionLog.subscriptRange[selfType]
    return base[bounds]
  }

  public var isEmpty: Bool {
    ++CollectionLog.isEmpty[selfType]
    return base.isEmpty
  }

  public var count: Base.Index.Distance {
    ++CollectionLog.count[selfType]
    return base.count
  }

  public func _customIndexOfEquatableElement(
    element: Base.Generator.Element
  ) -> Base.Index?? {
    ++CollectionLog._customIndexOfEquatableElement[selfType]
    return base._customIndexOfEquatableElement(element)
  }

  public var first: Base.Generator.Element? {
    ++CollectionLog.first[selfType]
    return base.first
  }

  public var base: Base
}

public func expectCustomizable<
  T : WrapperType where
  T : LoggingType,
  T.Base : WrapperType, T.Base : LoggingType,
  T.Log == T.Base.Log
>(_: T, _ counters: TypeIndexed<Int>,
  stackTrace: SourceLocStack? = nil,
  file: String = __FILE__, line: UWord = __LINE__,
  collectMoreInfo: (()->String)? = nil
) {
  expectNotEqual(
    0, counters[T.self], stackTrace: stackTrace,
    file: file, line: line, collectMoreInfo: collectMoreInfo)
  
  expectEqual(
    counters[T.self], counters[T.Base.self], stackTrace: stackTrace,
    file: file, line: line, collectMoreInfo: collectMoreInfo)
}

public func expectNotCustomizable<
  T : WrapperType where
  T : LoggingType,
  T.Base : WrapperType, T.Base : LoggingType,
  T.Log == T.Base.Log
>(_: T, _ counters: TypeIndexed<Int>,
  stackTrace: SourceLocStack? = nil,
  file: String = __FILE__, line: UWord = __LINE__,
  collectMoreInfo: (()->String)? = nil
) {
  expectNotEqual(
    0, counters[T.self], stackTrace: stackTrace,
    file: file, line: line, collectMoreInfo: collectMoreInfo)
  
  expectEqual(
    0, counters[T.Base.self], stackTrace: stackTrace,
    file: file, line: line, collectMoreInfo: collectMoreInfo)
}

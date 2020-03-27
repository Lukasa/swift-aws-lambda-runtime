//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftAWSLambdaRuntime open source project
//
// Copyright (c) 2017-2018 Apple Inc. and the SwiftAWSLambdaRuntime project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftAWSLambdaRuntime project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//
import NIO

/// Extension to the `Lambda` companion to enable execution of Lambdas that take and return `String` payloads.
extension Lambda {
    /// Run a Lambda defined by implementing the `StringLambdaClosure` function.
    ///
    /// - note: This is a blocking operation that will run forever, as its lifecycle is managed by the AWS Lambda Runtime Engine.
    public static func run(_ closure: @escaping StringLambdaClosure) {
        self.run(closure: closure)
    }

    /// Run a Lambda defined by implementing the `StringVoidLambdaClosure` function.
    ///
    /// - note: This is a blocking operation that will run forever, as its lifecycle is managed by the AWS Lambda Runtime Engine.
    public static func run(_ closure: @escaping StringVoidLambdaClosure) {
        self.run(closure: closure)
    }

    // for testing
    @discardableResult
    internal static func run(configuration: Configuration = .init(), closure: @escaping StringLambdaClosure) -> Result<Int, Error> {
        self.run(configuration: configuration, handler: StringLambdaClosureWrapper(closure))
    }

    // for testing
    @discardableResult
    internal static func run(configuration: Configuration = .init(), closure: @escaping StringVoidLambdaClosure) -> Result<Int, Error> {
        self.run(configuration: configuration, handler: StringVoidLambdaClosureWrapper(closure))
    }
}

/// A processing closure for a Lambda that takes a `String` and returns a `Result<String, Error>` via a `CompletionHandler` asynchronously.
public typealias StringLambdaClosure = (Lambda.Context, String, @escaping (Result<String, Error>) -> Void) -> Void

/// A processing closure for a Lambda that takes a `String` and returns a `Result<Void, Error>` via a `CompletionHandler` asynchronously.
public typealias StringVoidLambdaClosure = (Lambda.Context, String, @escaping (Result<Void, Error>) -> Void) -> Void

internal struct StringLambdaClosureWrapper: LambdaHandler {
    typealias In = String
    typealias Out = String

    private let closure: StringLambdaClosure

    init(_ closure: @escaping StringLambdaClosure) {
        self.closure = closure
    }

    func handle(context: Lambda.Context, payload: In, callback: @escaping (Result<Out, Error>) -> Void) {
        self.closure(context, payload, callback)
    }
}

internal struct StringVoidLambdaClosureWrapper: LambdaHandler {
    typealias In = String
    typealias Out = Void

    private let closure: StringVoidLambdaClosure

    init(_ closure: @escaping StringVoidLambdaClosure) {
        self.closure = closure
    }

    func handle(context: Lambda.Context, payload: In, callback: @escaping (Result<Out, Error>) -> Void) {
        self.closure(context, payload, callback)
    }
}

/// Implementation of  a`ByteBuffer` to `String` encoding
public extension EventLoopLambdaHandler where In == String {
    func decode(buffer: ByteBuffer) throws -> String {
        var buffer = buffer
        guard let string = buffer.readString(length: buffer.readableBytes) else {
            fatalError("buffer.readString(length: buffer.readableBytes) failed")
        }
        return string
    }
}

/// Implementation of  `String` to `ByteBuffer` decoding
public extension EventLoopLambdaHandler where Out == String {
    func encode(allocator: ByteBufferAllocator, value: String) throws -> ByteBuffer? {
        // FIXME: reusable buffer
        var buffer = allocator.buffer(capacity: value.utf8.count)
        buffer.writeString(value)
        return buffer
    }
}
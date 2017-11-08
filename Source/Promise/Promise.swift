//
//  Promise.swift
//  FlashCards
//
//  Created by Roy McKenzie on 12/18/16.
//  Copyright © 2016 Roy McKenzie. All rights reserved.
//

// from: https://github.com/khanlou/Promise

import Foundation

public protocol ExecutionContext {
    func execute(_ work: @escaping () -> Void)
}

extension DispatchQueue: ExecutionContext {
    public func execute(_ work: @escaping () -> Void) {
        self.async(execute: work)
    }
}

struct Callback<Value> {
    let onFulfilled: (Value) -> ()
    let onRejected: (Error) -> ()
    let queue: ExecutionContext
    
    func fulfill(_ value: Value) {
        queue.execute({
            self.onFulfilled(value)
        })
    }
    
    func reject(_ error: Error) {
        queue.execute({
            self.onRejected(error)
        })
    }
}

enum State<Value>: CustomStringConvertible {
    case pending
    case fulfilled(Value)
    case rejected(Error)
}

// MARK: CustomStringConvertable conformance
extension State {
    var description: String {
        switch self {
        case .fulfilled(let value):
            return "Fulfilled (\(value))"
        case .rejected(let error):
            return "Rejected (\(error))"
        case .pending:
            return "Pending"
        }
    }
}

// MARK:- State values
extension State {
    
    fileprivate var value: Value? {
        if case .fulfilled(let value) = self {
            return value
        }
        return nil
    }
    
    fileprivate var error: Error? {
        if case .rejected(let error) = self {
            return error
        }
        return nil
    }
}

// MARK:- State statuses
extension State {
    
    var isPending: Bool {
        if case .pending = self {
            return true
        } else {
            return false
        }
    }
    
    var isFulfilled: Bool {
        if case .fulfilled = self {
            return true
        } else {
            return false
        }
    }
    
    var isRejected: Bool {
        if case .rejected = self {
            return true
        } else {
            return false
        }
    }
}

/// Promise
public final class Promise<Value> {
    fileprivate var state: State<Value>
    fileprivate let lockQueue = DispatchQueue(label: "flashcards.queue.promise.lockqueue", qos: .userInitiated)
    fileprivate var callbacks = [Callback<Value>]()

    public init() {
        state = .pending
    }
    
    public init(value: Value) {
        state = .fulfilled(value)
    }
    
    public init(error: Error) {
        state = .rejected(error)
    }
    
    public convenience init(queue: DispatchQueue = DispatchQueue.global(qos: .userInitiated),
                            work: @escaping (_ fulfill: @escaping (Value) -> (), _ reject: @escaping (Error) -> () ) throws -> ()) {
        self.init()
        queue.async {
            do {
                try work(self.fulfill, self.reject)
            } catch {
                self.reject(error)
            }
        }
    }
}

// MARK:- Values
extension Promise {
    
    public var value: Value? {
        return lockQueue.sync {
            return state.value
        }
    }
    
    public var error: Error? {
        return lockQueue.sync {
            return state.error
        }
    }
}

// MARK:- Promise statuses
extension Promise {
    
    var isPending: Bool {
        return !isRejected && !isFulfilled
    }
    
    var isRejected: Bool {
        return error != nil
    }
    
    var isFulfilled: Bool {
        return value != nil
    }
}

// MARK:- Methods like `fulfill`, `reject`
extension Promise {
    
    public func fulfill(_ value: Value) {
        updateState(.fulfilled(value))
    }
    
    public func reject(_ error: Error) {
        updateState(.rejected(error))
    }
    
    private func updateState(_ state: State<Value>) {
        guard self.isPending else { return }
        lockQueue.async {
            self.state = state
        }
        fireCallbacksIfCompleted()
    }
}

// MARK:- Methods like `then`
extension Promise {

    /// - note: This one is "flatMap"
    @discardableResult
    public func then<U>(on queue: DispatchQueue = .main, _ onFulfilled: @escaping (Value) throws -> Promise<U>) -> Promise<U> {
        return Promise<U>(work: { fulfill, reject in
            self.addCallbacks(
                on: queue,
                onFulfilled: { value in
                    do {
                        try onFulfilled(value).then(fulfill, reject)
                    } catch let error {
                        reject(error)
                    }
            },
                onRejected: reject
            )
        })
    }
    
    /// - note: This one is "map"
    @discardableResult
    public func then<U>(on queue: DispatchQueue = .main, _ onFulfilled: @escaping (Value) throws -> U) -> Promise<U> {
        return then(on: queue, { (value) -> Promise<U> in
            do {
                return Promise<U>(value: try onFulfilled(value))
            } catch let error {
                return Promise<U>(error: error)
            }
        })
    }
    
    @discardableResult
    public func then(on queue: DispatchQueue = .main, _ onFulfilled: @escaping (Value) -> (), _ onRejected: @escaping (Error) -> () = { _ in }) -> Promise<Value> {
        return Promise<Value>(work: { fulfill, reject in
            self.addCallbacks(
                on: queue,
                onFulfilled: { value in
                    fulfill(value)
                    onFulfilled(value)
            },
                onRejected: { error in
                    reject(error)
                    onRejected(error)
            }
            )
        })
    }
    
    @discardableResult
    public func `catch`(on queue: DispatchQueue = .main, _ onRejected: @escaping (Error) -> ()) -> Promise<Value> {
        return then(on: queue, { _ in }, onRejected)
    }
    
    public static func all<T>(_ promises: [Promise<T>]) -> Promise<[T]> {
        return Promise<[T]>(work: { fulfill, reject in
            guard !promises.isEmpty else { fulfill([]); return }
            for promise in promises {
                promise.then({ value in
                    if !promises.contains(where: { $0.isRejected || $0.isPending }) {
                        fulfill(promises.flatMap({ $0.value }))
                    }
                }).catch({ error in
                    reject(error)
                })
            }
        })
    }
    
    public static func zip<T, U>(_ first: Promise<T>, and second: Promise<U>) -> Promise<(T, U)> {
        return Promise<(T, U)>(work: { fulfill, reject in
            let resolver: (Any) -> () = { _ in
                if let firstValue = first.value, let secondValue = second.value {
                    fulfill((firstValue, secondValue))
                }
            }
            first.then(resolver, reject)
            second.then(resolver, reject)
        })
    }
    
    @discardableResult
    public func always(on queue: DispatchQueue = .main, _ onComplete: @escaping () -> ()) -> Promise<Value> {
        return then(on: queue, { _ in
            onComplete()
        }, { _ in
            onComplete()
        })
    }
    
    fileprivate func addCallbacks(on queue: DispatchQueue = DispatchQueue.main,
                              onFulfilled: @escaping (Value) -> (),
                              onRejected: @escaping (Error) -> Void) {
        let callback = Callback(onFulfilled: onFulfilled, onRejected: onRejected, queue: queue)
        lockQueue.async {
            self.callbacks.append(callback)
        }
        fireCallbacksIfCompleted()
    }
    
    fileprivate func fireCallbacksIfCompleted() {
        lockQueue.async {
            guard !self.state.isPending else { return }
            self.callbacks.forEach { callback in
                switch self.state {
                case .fulfilled(let value):
                    callback.fulfill(value)
                case .rejected(let error):
                    callback.reject(error)
                default:
                    break
                }
            }
            self.callbacks.removeAll()
        }
    }
    
}

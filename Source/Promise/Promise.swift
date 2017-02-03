//
//  Promise.swift
//  FlashCards
//
//  Created by Roy McKenzie on 12/18/16.
//  Copyright © 2016 Roy McKenzie. All rights reserved.
//

// from: https://github.com/khanlou/Promise

import Foundation

struct Callback<T> {
    let onFulfilled: (T) -> Void
    let onRejected: (Error) -> Void
    let queue: DispatchQueue
    
    func fulfill(_ value: T) {
        queue.async {
            self.onFulfilled(value)
        }
    }
    
    func reject(_ error: Error) {
        queue.async {
            self.onRejected(error)
        }
    }
}

enum State<T> {
    case pending
    case fulfilled(T)
    case rejected(Error)
}

// MARK:- State values
extension State {
    
    fileprivate var value: T? {
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
public final class Promise<T> {
    fileprivate var state: State<T>
    fileprivate let lockQueue = DispatchQueue(label: "flashcards.queue.promise.lockqueue", qos: .userInitiated)
    fileprivate var callbacks = [Callback<T>]()

    public init() {
        state = .pending
    }
    
    public init(value: T) {
        state = .fulfilled(value)
    }
    
    public init(error: Error) {
        state = .rejected(error)
    }
    
    public convenience init(queue: DispatchQueue = DispatchQueue.global(qos: .userInitiated),
                            work: @escaping (_ fulfill: @escaping (T) -> Void, _ reject: @escaping (Error) -> Void ) throws -> Void) {
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
    
    public var value: T? {
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
    
    public func fulfill(_ value: T) {
        updateState(.fulfilled(value))
    }
    
    public func reject(_ error: Error) {
        updateState(.rejected(error))
    }
    
    private func updateState(_ state: State<T>) {
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
    public func then<U>(on queue: DispatchQueue = .main, _ onFulfilled: @escaping (T) throws -> Promise<U>) -> Promise<U> {
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
    public func then<U>(on queue: DispatchQueue = .main, _ onFulfilled: @escaping (T) throws -> U) -> Promise<U> {
        return then(on: queue, { (value) -> Promise<U> in
            do {
                return Promise<U>(value: try onFulfilled(value))
            } catch let error {
                return Promise<U>(error: error)
            }
        })
    }
    
    @discardableResult
    public func then(on queue: DispatchQueue = .main, _ onFulfilled: @escaping (T) -> Void, _ onRejected: @escaping (Error) -> Void = { _ in }) -> Promise<T> {
        return Promise<T>(work: { fulfill, reject in
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
    public func `catch`(on queue: DispatchQueue = .main, _ onRejected: @escaping (Error) -> Void) -> Promise<T> {
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
    public func always(on queue: DispatchQueue = .main, _ onComplete: @escaping () -> Void) -> Promise<T> {
        return then(on: queue, { _ in
            onComplete()
        }, { _ in
            onComplete()
        })
    }
    
    fileprivate func addCallbacks(on queue: DispatchQueue = DispatchQueue.main,
                              onFulfilled: @escaping (T) -> Void,
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

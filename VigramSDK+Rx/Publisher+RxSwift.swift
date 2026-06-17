//
//  Publisher+RxSwift.swift
//  VigramSDK+Rx
//
//  Created by Khaustov Iaroslav
//

import Foundation
import Combine
@_exported import RxSwift
@_exported import VigramSDK

/// Errors emitted by the optional RxSwift bridge.
enum VigramRxBridgeError: LocalizedError {

    /// The Combine publisher completed before emitting a value required by `Single`.
    case noElements

    var errorDescription: String? {
        switch self {
        case .noElements:
            return "The publisher completed without emitting a value."
        }
    }
}

public extension Publisher {

    /// Converts any Combine publisher returned by VigramSDK to an RxSwift observable.
    ///
    /// Use this for SDK state and event streams, such as `StatePublisher` or `EventsPublisher`.
    func asObservable() -> Observable<Output> {
        Observable.create { observer in
            let cancellable = self.sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        observer.onCompleted()
                    case .failure(let error):
                        observer.onError(error)
                    }
                },
                receiveValue: { value in
                    observer.onNext(value)
                }
            )

            return Disposables.create {
                cancellable.cancel()
            }
        }
    }

    /// Converts the first value emitted by a Combine publisher to an RxSwift single.
    ///
    /// Use this for one-shot SDK operations, such as `SingleEventPublisher`.
    /// If the publisher completes before emitting a value, the single fails.
    func asSingle() -> Single<Output> {
        Single.create { single in
            var didEmitValue = false
            var cancellable: AnyCancellable?

            cancellable = self.sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        if !didEmitValue {
                            single(.failure(VigramRxBridgeError.noElements))
                        }
                    case .failure(let error):
                        if !didEmitValue {
                            single(.failure(error))
                        }
                    }

                    cancellable?.cancel()
                    cancellable = nil
                },
                receiveValue: { value in
                    guard !didEmitValue else { return }

                    didEmitValue = true
                    single(.success(value))
                    cancellable?.cancel()
                    cancellable = nil
                }
            )

            return Disposables.create {
                cancellable?.cancel()
                cancellable = nil
            }
        }
    }
}

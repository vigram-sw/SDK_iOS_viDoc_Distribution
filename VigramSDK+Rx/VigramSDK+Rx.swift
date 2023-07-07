//
//  VigramSDK+Rx.swift
//  
//
//  Created by Paul Kraft on 24.09.21.
//

@_exported import Combine
@_exported import RxSwift
@_exported import VigramSDK

extension AnyPublisher: ObservableType {

    public typealias Element = Output

    public func subscribe<Observer: ObserverType>(_ observer: Observer) -> Disposable where Output == Observer.Element {
        let cancellable = self.sink(
            receiveCompletion: { completion in
                switch completion {
                case .finished:
                    observer.onCompleted()
                case let .failure(error):
                    observer.onError(error)
                }
            },
            receiveValue: { value in
                observer.onNext(value)
            }
        )

        return Disposables.create { cancellable.cancel() }
    }
}

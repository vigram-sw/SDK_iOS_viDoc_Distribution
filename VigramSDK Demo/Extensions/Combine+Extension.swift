//
//  Combine+Extension.swift
//  VigramSDK Demo
//
//  Created by Aleksei Sablin on 13.12.2023.
//  Copyright © 2023 Vigram GmbH. All rights reserved.
//

import Combine

public typealias SinglePublisher<Element> = AnyPublisher<Element, Never>
public typealias Current<Element> = CurrentValueSubject<Element, Never>
public typealias Passthrough<Element> = PassthroughSubject<Element, Never>

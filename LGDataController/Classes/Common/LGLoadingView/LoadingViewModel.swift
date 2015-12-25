//
//  LoadingViewModel.swift
//  LGDataController
//
//  Created by Luka Gabric on 22/12/15.
//  Copyright © 2015 Luka Gabric. All rights reserved.
//

import Foundation
import ReactiveCocoa
import Rex

public protocol LoadingViewModelType {
    
    var modelLoadedProducer: SignalProducer<Void, NoError> { get }
    var loadingViewHidden: AnyProperty<Bool> { get }
    var contentUnavailableViewHidden: AnyProperty<Bool> { get }
    var contentUnavailableText: AnyProperty<String> { get }
    
}

public class LoadingViewModel: LoadingViewModelType {
    
    private let reachabilityService: ReachabilityServiceType
    private let loadProducerClosure: () -> SignalProducer<Bool, NSError>
    
    private let isLoadingData = MutableProperty<Bool>(false)
    
    public let modelLoadedProducer: SignalProducer<Void, NoError>
    private let modelLoadedObserver: Observer<Void, NoError>
    
    private var onLoadSuccessProducer: SignalProducer<Void, NoError> = SignalProducer.empty
    
    public let loadingViewHidden: AnyProperty<Bool>
    private let mutableLoadingViewHidden = MutableProperty<Bool>(true)
    
    public let contentUnavailableViewHidden: AnyProperty<Bool>
    private let mutableContentUnavailableViewHidden = MutableProperty<Bool>(true)
    
    public let contentUnavailableText: AnyProperty<String>
    private let mutableContentUnavailableText = MutableProperty<String>("")
    
    private let isOffline: MutableProperty<Bool>
    
    public init(reachabilityService: ReachabilityServiceType, loadProducerClosure: () -> SignalProducer<Bool, NSError>) {
        self.reachabilityService = reachabilityService
        self.loadProducerClosure = loadProducerClosure
        
        self.loadingViewHidden = AnyProperty(self.mutableLoadingViewHidden)
        self.contentUnavailableViewHidden = AnyProperty(self.mutableContentUnavailableViewHidden)
        self.contentUnavailableText = AnyProperty(self.mutableContentUnavailableText)
        self.isOffline = self.reachabilityService.isOffline
        (self.modelLoadedProducer, self.modelLoadedObserver) = SignalProducer.buffer(1)
        
        self.reachabilityService.reachability.producer
            .skip(1)
            .takeUntil(self.modelLoadedProducer)
            .startWithNext { [weak self] reachability in
                guard let sself = self where
                    reachability.isReachable() && !sself.isLoadingData.value else { return }
                
                sself.configureLoadingBindingsForModelProducer()
        }
        
        self.configureLoadingBindingsForModelProducer()
    }
    
    private func configureLoadingBindingsForModelProducer() {
        let trueProducer = SignalProducer<Bool, NoError>(value: true)
        
        let loadProducer = self.loadProducerClosure()
        let isLoadSuccessProducer = loadProducer.flatMapError { _ in SignalProducer<Bool, NoError>(value: false) }
        let falseOnLoadComplete = isLoadSuccessProducer.map { _ in false }
        
        let isOfflineProducer = self.isOffline.producer
        let didLoadFailWithErrorProducer = loadProducer
            .map { _ in false }
            .flatMapError { _ in SignalProducer<Bool, NoError>(value: true) }
        
        self.onLoadSuccessProducer = isLoadSuccessProducer.filter { $0 == true }.map { _ in () }
        self.onLoadSuccessProducer.startWithNext { [weak self] in
            self?.modelLoadedObserver.sendCompleted()
        }
        
        self.isLoadingData <~ trueProducer.concat(falseOnLoadComplete)
        self.mutableLoadingViewHidden <~ self.isLoadingData.producer.map { !$0 }
        self.mutableContentUnavailableViewHidden <~ trueProducer.concat(isLoadSuccessProducer)
        self.mutableContentUnavailableText <~ combineLatest(isOfflineProducer, didLoadFailWithErrorProducer)
            .map { isOffline, didFailWithError -> String in
                if isOffline { return "You're offline." }
                else if didFailWithError { return "An error has occured during load. Please try again later." }
                return "No content available."
        }
    }
    
}

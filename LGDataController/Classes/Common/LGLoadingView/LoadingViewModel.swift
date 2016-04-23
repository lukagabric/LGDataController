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

public class LoadingViewModel {
    
    private let reachabilityService: ReachabilityService
    private let loadProducerClosure: () -> SignalProducer<Void, NSError>?
    
    public let loadSuccessProducer: SignalProducer<Void, NoError>
    private let loadSuccessObserver: Observer<SignalProducer<Void, NoError>, NoError>
    
    private let isLoadingData = MutableProperty<Bool>(false)
    
    public let loadingViewHidden: AnyProperty<Bool>
    private let mutableLoadingViewHidden = MutableProperty<Bool>(true)
    
    public let contentUnavailableViewHidden: AnyProperty<Bool>
    private let mutableContentUnavailableViewHidden = MutableProperty<Bool>(true)
    
    public let contentUnavailableText: AnyProperty<String>
    private let mutableContentUnavailableText = MutableProperty<String>("")
    
    public init(reachabilityService: ReachabilityService, loadProducerClosure: () -> SignalProducer<Void, NSError>?) {
        self.reachabilityService = reachabilityService
        self.loadProducerClosure = loadProducerClosure
        
        self.loadingViewHidden = AnyProperty(self.mutableLoadingViewHidden)
        self.contentUnavailableViewHidden = AnyProperty(self.mutableContentUnavailableViewHidden)
        self.contentUnavailableText = AnyProperty(self.mutableContentUnavailableText)
        
        let (p, o) = SignalProducer<SignalProducer<Void, NoError>, NoError>.buffer(1)
        self.loadSuccessProducer = p.flatten(.Latest)
        self.loadSuccessObserver = o
        
        self.reachabilityService.isOnlineProducer
            .takeUntil(self.loadSuccessProducer)
            .skip(1)
            .filter { $0 == true }
            .startWithNext { [weak self] reachability in
                guard let sself = self where !sself.isLoadingData.value else { return }
                
                sself.configureLoadingBindingsForModelProducer()
        }

        self.configureLoadingBindingsForModelProducer()
    }
    
    private func configureLoadingBindingsForModelProducer() {
        let loadProducer = self.loadProducerClosure() ?? SignalProducer(value: ())
        
        let onLoadSuccessProducer = loadProducer
            .map { _ in () }
            .flatMapError { _ in SignalProducer<Void, NoError>.empty }
        self.loadSuccessObserver.sendNext(onLoadSuccessProducer)
        
        let didLoadFailWithErrorProducer = loadProducer
            .map { _ in false }
            .flatMapError { _ in SignalProducer<Bool, NoError>(value: true) }
        let isLoadSuccessProducer = didLoadFailWithErrorProducer.map { !$0 }
        
        let falseOnLoadComplete = loadProducer
            .map { _ in false }
            .flatMapError { _ in SignalProducer<Bool, NoError>(value: false) }
        
        let trueProducer = SignalProducer<Bool, NoError>(value: true)

        self.isLoadingData <~ trueProducer.concat(falseOnLoadComplete)
        self.mutableLoadingViewHidden <~ self.isLoadingData.producer.map { !$0 }
        self.mutableContentUnavailableViewHidden <~ trueProducer.concat(isLoadSuccessProducer)
        self.mutableContentUnavailableText <~ self.reachabilityService.isOfflineProducer.map {
            if $0 { return "You're offline." }
            return "An error has occured during load. Please try again later."
        }
        
    }
    
}

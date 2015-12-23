//
//  LoadingViewController.swift
//  LGDataController
//
//  Created by Luka Gabric on 22/12/15.
//  Copyright © 2015 Luka Gabric. All rights reserved.
//

import Foundation

import ReactiveCocoa
import Rex

public protocol LoadingViewModelType {
    
    var modelLoaded: AnyProperty<Bool> { get }
    var loadingViewHidden: AnyProperty<Bool> { get }
    var contentUnavailableViewHidden: AnyProperty<Bool> { get }
    var contentUnavailableText: AnyProperty<String> { get }

}

public class LoadingViewModel: LoadingViewModelType {
    
    private let reachabilityService: ReachabilityServiceType
    private let loadProducerClosure: () -> SignalProducer<Bool, NSError>

    private let isLoadingData = MutableProperty<Bool>(false)

    public let modelLoaded: AnyProperty<Bool>
    public let mutableModelLoaded = MutableProperty<Bool>(false)

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
        self.modelLoaded = AnyProperty(self.mutableModelLoaded)

        self.reachabilityService.reachability.producer
            .skip(1)
            .startWithNext { [weak self] reachability in
                guard let sself = self where
                    reachability.isReachable() && !sself.isLoadingData.value && !sself.mutableModelLoaded.value else { return }

                sself.configureLoadingBindingsForModelProducer()
        }
        
        self.configureLoadingBindingsForModelProducer()
    }
    
    private func configureLoadingBindingsForModelProducer() {
        let trueProducer = SignalProducer<Bool, NoError>(value: true)
        let falseProducer = SignalProducer<Bool, NoError>(value: false)

        let loadProducer = self.loadProducerClosure()
        let isLoadSuccessProducer = loadProducer.flatMapError { _ in SignalProducer<Bool, NoError>(value: false) }
        let falseOnLoadComplete = isLoadSuccessProducer.map { _ in false }
        
        let isOfflineProducer = self.isOffline.producer
        let didLoadFailWithErrorProducer = loadProducer
            .flatMapError { _ in SignalProducer<Bool, NoError>(value: true) }
            .map { _ in false }
        
        self.isLoadingData <~ trueProducer.concat(falseOnLoadComplete)
        self.mutableModelLoaded <~ falseProducer.concat(isLoadSuccessProducer.filter { $0 == true })
        
        self.mutableLoadingViewHidden <~ self.isLoadingData.producer.map { !$0 }
        self.mutableContentUnavailableViewHidden <~ trueProducer.concat(isLoadSuccessProducer)
        self.mutableContentUnavailableText <~ combineLatest(isOfflineProducer, didLoadFailWithErrorProducer)
            .map { isOffline, didFailWithError -> String in
                if isOffline { return "You're offline." }
                else if didFailWithError { return "An error has occured during load. Please try again later." }
                return "This content is no longer available."
        }
        
    }
    
}

public class LoadingViewController: UIViewController {

    var loadingViewModel: LoadingViewModelType!
    weak var loadingView: LGLoadingView!
    weak var contentUnavailableView: LGTextOverlayView!
    
    //MARK: - Init
    
    init(loadingViewModel: LoadingViewModelType) {
        self.loadingViewModel = loadingViewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    //MARK: - View Lifecycle
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        self.edgesForExtendedLayout = .None
        
        self.loadingView = LGLoadingView.attachToView(self.view)
        self.loadingView.rex_hidden <~ self.loadingViewModel.loadingViewHidden
        self.contentUnavailableView = LGTextOverlayView.attachToView(self.view)
        self.contentUnavailableView.rex_hidden <~ self.loadingViewModel.contentUnavailableViewHidden
        self.contentUnavailableView.rac_text <~ self.loadingViewModel.contentUnavailableText
    }
    
}

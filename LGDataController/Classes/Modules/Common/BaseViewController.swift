//
//  BaseViewController.swift
//  LGDataController
//
//  Created by Luka Gabric on 22/12/15.
//  Copyright © 2015 Luka Gabric. All rights reserved.
//

import Foundation

import ReactiveCocoa
import Rex

public protocol BaseViewModelType {
    
    var loadingViewHidden: AnyProperty<Bool> { get }
    var contentUnavailableViewHidden: AnyProperty<Bool> { get }
    var contentUnavailableText: AnyProperty<String> { get }
    
}

public class BaseViewModel<T: ContentEntity>: BaseViewModelType {
    let reachabilityService: ReachabilityServiceType

    public var modelProducer: SignalProducer<T?, NSError>! {
        didSet {
            self.configureBindingsForModelProducer()
        }
    }

    public var model: AnyProperty<T?>!
    var mutableModel = MutableProperty<T?>(nil)
    
    public let loadingData = MutableProperty<Bool>(false)

    public let loadingViewHidden: AnyProperty<Bool>
    let mutableLoadingViewHidden = MutableProperty<Bool>(true)
    
    public let contentUnavailableViewHidden: AnyProperty<Bool>
    let mutableContentUnavailableViewHidden = MutableProperty<Bool>(true)
    
    public let contentUnavailableText: AnyProperty<String>
    let mutableContentUnavailableText = MutableProperty<String>("")
    
    let isOffline: MutableProperty<Bool>
    
    var takeUntilProducer: SignalProducer<Void, NoError>?

    public init(reachabilityService: ReachabilityServiceType) {
        self.reachabilityService = reachabilityService

        self.model = AnyProperty(self.mutableModel)
        self.loadingViewHidden = AnyProperty(self.mutableLoadingViewHidden)
        self.contentUnavailableViewHidden = AnyProperty(self.mutableContentUnavailableViewHidden)
        self.contentUnavailableText = AnyProperty(self.mutableContentUnavailableText)
        self.isOffline = self.reachabilityService.isOffline
        
        self.reachabilityService.reachability.producer
            .skip(1)
            .startWithNext { [weak self] reachability in
                guard let sself = self where
                    reachability.isReachable() && !sself.loadingData.value && sself.mutableModel.value == nil else { return }

                sself.configureBindings()
        }
    }
    
    func configureBindings() {}
    
    private func configureBindingsForModelProducer() {
        let trueProducer = SignalProducer<Bool, NoError>(value: true)
        let falseProducer = SignalProducer<Bool, NoError>(value: false)
        let nilModelProducer = SignalProducer<T?, NoError>(value: nil)
        
        let modelOrNilProducer = self.modelProducer.flatMapError { _ in SignalProducer<T?, NoError>(value: nil) }
        let modelProducer = modelOrNilProducer.filter { $0 != nil }
        
        let loadingProducer = trueProducer.concat(modelOrNilProducer.map { _ in false})
        
        let modelDeletedEventProducer = modelProducer.flatMap(.Concat) { $0!.deleteProducer }
        let falseOnModelDeletedProducer = modelDeletedEventProducer.map { _ in false }
        let firstFalseThenTrueOnModelDeletedProducer = falseProducer.concat(modelDeletedEventProducer.map { _ in true })

        let modelAvailableAfterLoad = modelOrNilProducer.map { $0 != nil }
        let modelAvailableProducer = modelAvailableAfterLoad.concat(falseOnModelDeletedProducer)
        
        let mutableModelProducer = nilModelProducer.concat(modelProducer)
        let mutableLoadingViewHiddenProducer = loadingProducer.map { !$0 }
        let loadingDataProducer = loadingProducer
        let mutableContentUnavailableViewHiddenProducer = loadingProducer.filter { $0 == true }.concat(modelAvailableProducer)
        let mutableContentUnavailableTextProducer = self.isOffline.producer.combineLatestWith(firstFalseThenTrueOnModelDeletedProducer)
            .map { return $0 && !$1 ? "You're offline." : "Content not available." }

        if let takeUntilProducer = self.takeUntilProducer {
            self.mutableModel <~ mutableModelProducer.takeUntil(takeUntilProducer)
            self.mutableLoadingViewHidden <~ mutableLoadingViewHiddenProducer.takeUntil(takeUntilProducer)
            self.loadingData <~ loadingDataProducer.takeUntil(takeUntilProducer)
            self.mutableContentUnavailableViewHidden <~ mutableContentUnavailableViewHiddenProducer.takeUntil(takeUntilProducer)
            self.mutableContentUnavailableText <~ mutableContentUnavailableTextProducer.takeUntil(takeUntilProducer)
        }
        else {
            self.mutableModel <~ mutableModelProducer
            self.mutableLoadingViewHidden <~ mutableLoadingViewHiddenProducer
            self.loadingData <~ loadingDataProducer
            self.mutableContentUnavailableViewHidden <~ mutableContentUnavailableViewHiddenProducer
            self.mutableContentUnavailableText <~ mutableContentUnavailableTextProducer
        }
    }
    
}

public class BaseViewController: UIViewController {

    var baseViewModel: BaseViewModelType!
    weak var loadingView: LGLoadingView!
    weak var contentUnavailableView: LGTextOverlayView!
    
    //MARK: - Init
    
    init(baseViewModel: BaseViewModelType) {
        self.baseViewModel = baseViewModel
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
        self.loadingView.rex_hidden <~ self.baseViewModel.loadingViewHidden
        self.contentUnavailableView = LGTextOverlayView.attachToView(self.view)
        self.contentUnavailableView.rex_hidden <~ self.baseViewModel.contentUnavailableViewHidden
        self.contentUnavailableView.rac_text <~ self.baseViewModel.contentUnavailableText
    }
    
}

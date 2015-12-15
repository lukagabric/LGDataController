//
//  LGLoadingView.swift
//  LGDataController
//
//  Created by Luka Gabric on 15/12/15.
//  Copyright © 2015 Luka Gabric. All rights reserved.
//

import UIKit
import ReactiveCocoa

class LGLoadingView: UIView {
    
    //MARK: Attach

    class func attachToView<T, U>(view: UIView, entity: Any?, updateProducer: SignalProducer<T, U>?) -> LGLoadingView {
        let loadingView = LGLoadingView(frame: view.bounds)
        loadingView.backgroundColor = UIColor(white: 0, alpha: 0.6)
        loadingView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        loadingView.hidden = true
        view.addSubview(loadingView)
        
        let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .WhiteLarge)
        loadingView.addSubview(activityIndicator)
        activityIndicator.center = loadingView.center
        activityIndicator.autoresizingMask = [.FlexibleTopMargin, .FlexibleBottomMargin, .FlexibleLeftMargin, .FlexibleRightMargin]
        activityIndicator.startAnimating()
        
        if entity != nil { return loadingView }
        guard let updateProducer = updateProducer else { return loadingView }
        
        loadingView.rac_hidden <~ self.loadingProducerFrom(updateProducer).map { !$0 }
        
        return loadingView
    }
    
    //MARK: - Loading Producer
    
    class func loadingProducerFrom<T, U>(producer: SignalProducer<T, U>?) -> SignalProducer<Bool, NoError> {
        guard let producer = producer else { return SignalProducer<Bool, NoError>(value: false) }
        
        let (loadingProducer, loadingObserver) = SignalProducer<Bool, NoError>.buffer(1)
        loadingObserver.sendNext(true)
        
        producer
            .map { _ in false }
            .flatMapError { _ in SignalProducer<Bool, NoError>(value: false) }
            .takeLast(1)
            .start { event in
                if event.isTerminating {
                    loadingObserver.sendNext(false)
                }
        }
        
        return loadingProducer
    }
    
    //MARK: -

}

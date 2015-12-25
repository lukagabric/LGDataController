//
//  LGLoadingView.swift
//  LGDataController
//
//  Created by Luka Gabric on 15/12/15.
//  Copyright © 2015 Luka Gabric. All rights reserved.
//

import UIKit
import ReactiveCocoa

public class LGLoadingView: UIView {
    
    //MARK: Attach

    class func attachToView(view: UIView, loadingViewModel: LoadingViewModelType) -> LGLoadingView {
        let loadingView = LGLoadingView(frame: view.bounds, loadingViewModel: loadingViewModel)
        loadingView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        view.addSubview(loadingView)
        
        return loadingView
    }

    private var label: UILabel!
    private var activityIndicator: UIActivityIndicatorView!
    private var loadingViewModel: LoadingViewModelType!
    
    init(frame: CGRect, loadingViewModel: LoadingViewModelType) {
        super.init(frame: frame)
        
        self.loadingViewModel = loadingViewModel
        
        self.backgroundColor = UIColor(white: 0, alpha: 0.6)
//        loadingView.backgroundColor = UIColor.lightGrayColor()
        
        self.activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .WhiteLarge)
        self.activityIndicator.center = self.center
        self.activityIndicator.autoresizingMask = [.FlexibleTopMargin, .FlexibleBottomMargin, .FlexibleLeftMargin, .FlexibleRightMargin]
        self.activityIndicator.startAnimating()
        self.addSubview(self.activityIndicator)

        self.label = UILabel(frame: frame)
        self.label.textAlignment = .Center
        self.label.numberOfLines = 0
        self.label.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        self.addSubview(self.label)
    }
    
    public override func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        self.loadingViewModel.modelLoadedProducer.startWithCompleted { [weak self] in
            self?.removeFromSuperview()
        }
        
        self.activityIndicator.rac_stopped <~ self.loadingViewModel.loadingViewHidden
        self.label.rex_hidden <~ self.loadingViewModel.contentUnavailableViewHidden
        self.label.rex_text <~ self.loadingViewModel.contentUnavailableText
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

}

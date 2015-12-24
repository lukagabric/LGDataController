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
        self.addSubview(self.activityIndicator)
        self.activityIndicator.center = self.center
        self.activityIndicator.autoresizingMask = [.FlexibleTopMargin, .FlexibleBottomMargin, .FlexibleLeftMargin, .FlexibleRightMargin]
        self.activityIndicator.startAnimating()

        self.label = UILabel(frame: frame)
        self.label.textAlignment = .Center
        self.label.numberOfLines = 0
        self.label.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        self.addSubview(self.label)
        
        self.activityIndicator.rex_hidden <~ self.loadingViewModel.loadingViewHidden
        self.label.rex_hidden <~ self.loadingViewModel.contentUnavailableViewHidden
        self.label.rex_text <~ self.loadingViewModel.contentUnavailableText
        
        self.loadingViewModel.modelLoaded.producer
            .filter { $0 == true }
            .startWithNext { [weak self] _ in self?.removeFromSuperview() }
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

}

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

    class func attachToView(view: UIView) -> LGLoadingView {
        let loadingView = LGLoadingView(frame: view.bounds)
        loadingView.backgroundColor = UIColor(white: 0, alpha: 0.6)
//        loadingView.backgroundColor = UIColor.lightGrayColor()
        loadingView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        loadingView.hidden = true
        view.addSubview(loadingView)
        
        let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .WhiteLarge)
        loadingView.addSubview(activityIndicator)
        activityIndicator.center = loadingView.center
        activityIndicator.autoresizingMask = [.FlexibleTopMargin, .FlexibleBottomMargin, .FlexibleLeftMargin, .FlexibleRightMargin]
        activityIndicator.startAnimating()
        
        return loadingView
    }

}

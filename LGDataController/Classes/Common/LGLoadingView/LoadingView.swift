//
//  LoadingView.swift
//  LGDataController
//
//  Created by Luka Gabric on 15/12/15.
//  Copyright © 2015 Luka Gabric. All rights reserved.
//

import UIKit
import ReactiveCocoa

public class LoadingView: UIView {
    
    //MARK: Attach

    class func attachToView(view: UIView, loadingViewModel: LoadingViewModel) -> LoadingView {
        let loadingView = LoadingView(frame: view.bounds, loadingViewModel: loadingViewModel)
        loadingView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        view.addSubview(loadingView)
        loadingView.configureBindings()
        
        return loadingView
    }

    private var label: UILabel!
    private var activityIndicator: UIActivityIndicatorView!
    private let loadingViewModel: LoadingViewModel
    
    init(frame: CGRect, loadingViewModel: LoadingViewModel) {
        self.loadingViewModel = loadingViewModel

        super.init(frame: frame)
        
        self.backgroundColor = UIColor.lightGrayColor()
        
        self.activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .WhiteLarge)
        self.activityIndicator.center = self.center
        self.activityIndicator.autoresizingMask = [.FlexibleTopMargin, .FlexibleBottomMargin, .FlexibleLeftMargin, .FlexibleRightMargin]
        self.activityIndicator.startAnimating()
        self.addSubview(self.activityIndicator)

        self.label = UILabel(frame: frame)
        self.label.textAlignment = .Center
        self.label.numberOfLines = 0
        self.label.textColor = UIColor.blackColor()
        self.label.font = UIFont.boldSystemFontOfSize(17)
        self.label.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        self.addSubview(self.label)
    }
    
    public func configureBindings() {
        self.loadingViewModel.loadSuccessProducer.startWithNext { [weak self] in
            guard let sself = self else { return }
            sself.removeFromSuperview()
        }
        
        self.activityIndicator.rac_stopped <~ self.loadingViewModel.loadingViewHidden
        self.label.rex_hidden <~ self.loadingViewModel.contentUnavailableViewHidden
        self.label.rex_text <~ self.loadingViewModel.contentUnavailableText
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("NSCoding not supported")
    }

}

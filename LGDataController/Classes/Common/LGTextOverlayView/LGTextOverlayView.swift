//
//  LGTextOverlayView.swift
//  LGDataController
//
//  Created by Luka Gabric on 17/12/15.
//  Copyright © 2015 Luka Gabric. All rights reserved.
//

import UIKit

public class LGTextOverlayView: UIView {
    
    class func contentUnavailableViewAttachToView(view: UIView) -> LGTextOverlayView {
        let overlayView = LGTextOverlayView(frame: view.bounds, text: "Content not available")
        overlayView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        view.addSubview(overlayView)
        
        overlayView.backgroundColor = UIColor(white: 0, alpha: 0.6)

        return overlayView
    }

    init(frame: CGRect, text: String) {
        super.init(frame: frame)
        
        self.backgroundColor = UIColor.lightGrayColor()

        let label = UILabel(frame: frame)
        label.text = text
        label.textAlignment = .Center
        label.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        self.addSubview(label)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

}

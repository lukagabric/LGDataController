//
//  LGTextOverlayView.swift
//  LGDataController
//
//  Created by Luka Gabric on 17/12/15.
//  Copyright © 2015 Luka Gabric. All rights reserved.
//

import UIKit

public class LGTextOverlayView: UIView {
    
    class func contentUnavailableView(frame frame: CGRect, addedToView: UIView) -> LGTextOverlayView {
        let overlayView = LGTextOverlayView(frame: frame, text: "Content not available")
        addedToView.addSubview(overlayView)
        return overlayView
    }

    init(frame: CGRect, text: String) {
        super.init(frame: frame)
        
        self.backgroundColor = UIColor.whiteColor()

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

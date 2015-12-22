//
//  LGTextOverlayView.swift
//  LGDataController
//
//  Created by Luka Gabric on 17/12/15.
//  Copyright © 2015 Luka Gabric. All rights reserved.
//

import UIKit
import ReactiveCocoa
import Rex

public class LGTextOverlayView: UIView {
    
    class func attachToView(view: UIView) -> LGTextOverlayView {
        let overlayView = LGTextOverlayView(frame: view.bounds)
        overlayView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        view.addSubview(overlayView)
        
        overlayView.backgroundColor = UIColor(white: 0, alpha: 0.6)

        return overlayView
    }
    
    public var label: UILabel!

    public var rac_text: MutableProperty<String> {
        return self.label.rex_text
    }
    
    override init(frame: CGRect) {
        self.label = UILabel(frame: frame)
        
        super.init(frame: frame)

        self.backgroundColor = UIColor.lightGrayColor()

        self.label.textAlignment = .Center
        self.label.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        self.addSubview(self.label)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

}

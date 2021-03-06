//
//  Util.swift
//  ReactiveTwitterSearch
//
//  Created by Colin Eberhardt on 10/05/2015.
//  Copyright (c) 2015 Colin Eberhardt. All rights reserved.
//


import UIKit
import ReactiveCocoa

public struct AssociationKey {
    static var stopped: UInt8 = 1
    static var text: UInt8 = 2
    static var title: UInt8 = 3
    static var tableReload: UInt = 4
}

// lazily creates a gettable associated property via the given factory
public func lazyAssociatedProperty<T: AnyObject>(host: AnyObject, key: UnsafePointer<Void>, factory: ()->T) -> T {
  return objc_getAssociatedObject(host, key) as? T ?? {
    let associatedProperty = factory()
    objc_setAssociatedObject(host, key, associatedProperty, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
    return associatedProperty
  }()
}

public func lazyMutableProperty<T>(host: AnyObject, key: UnsafePointer<Void>, setter: T -> (), getter: () -> T) -> MutableProperty<T> {
  return lazyAssociatedProperty(host, key: key) {
    let property = MutableProperty<T>(getter())
    property.producer
        .startWithNext{
            newValue in
            setter(newValue)
      }
    
    return property
  }
}

extension UIActivityIndicatorView {
    public var rac_stopped: MutableProperty<Bool> {
        return lazyAssociatedProperty(self, key: &AssociationKey.stopped) {
            let property = MutableProperty<Bool>(true)
            property.producer
                .startWithNext { stopped in
                    if stopped {
                        self.stopAnimating()
                    }
                    else {
                        self.startAnimating()
                    }
            }
            return property
        }
    }
}

extension UIViewController {
    public var rac_title: MutableProperty<String> {
        return lazyMutableProperty(self, key: &AssociationKey.title, setter: { [weak self] in self?.title = $0 }, getter: { [weak self] in self?.title ?? "" })
    }
}

extension UITextField {
  public var rac_text: MutableProperty<String> {
    return lazyAssociatedProperty(self, key: &AssociationKey.text) {
      
      self.addTarget(self, action: #selector(self.changed), forControlEvents: UIControlEvents.EditingChanged)
      
      let property = MutableProperty<String>(self.text ?? "")
      property.producer
        .startWithNext {
          newValue in
          self.text = newValue
        }
      return property
    }
  }
  
  func changed() {
    rac_text.value = self.text ?? ""
  }
}

extension UITableView {
    public var rac_tableReload: MutableProperty<Void> {
        return lazyAssociatedProperty(self, key: &AssociationKey.tableReload) {
            let property = MutableProperty<Void>(())
            property.producer
                .startWithNext {
                    self.reloadData()
            }
            return property
        }
    }

}

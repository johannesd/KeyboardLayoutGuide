//
//  UIViewController+KeyboardLayoutGuide.swift
//  KeyboardLayoutGuide
//
//  Created by Johannes Dörr on 24.10.17.
//  Copyright © 2018 Johannes Dörr. All rights reserved.
//

import UIKit
import FirstResponder

var keyboardWillChangeFrameObserverKey: UInt8 = 0
var keyboardWillHideObserverKey: UInt8 = 0
var keyboardLayoutGuideKey: UInt8 = 0
var keyboardLayoutGuideConstraintKey: UInt8 = 0
var keyboardLayoutGuideAccessoryViewConstraintKey: UInt8 = 0
var keyboardLayoutGuideWillDisappearKey: UInt8 = 0
var keyboardLayoutGuideWillAppearKey: UInt8 = 0

private func replaceImplementation(_ originalSelector: Selector, with swizzledSelector: Selector, of object: NSObject.Type) {
    let originalMethod = class_getInstanceMethod(object, originalSelector)!
    let swizzledMethod = class_getInstanceMethod(object, swizzledSelector)!
    method_exchangeImplementations(originalMethod, swizzledMethod)
}

private let keyboardLayoutGuideSwizzling: (UIViewController.Type) -> Void = { viewController in
    replaceImplementation(#selector(viewController.viewWillAppear(_:)),
                          with: #selector(viewController.keyboardLayoutGuide_viewWillAppear(_:)),
                          of: viewController)
    replaceImplementation(#selector(viewController.viewDidAppear(_:)),
                          with: #selector(viewController.keyboardLayoutGuide_viewDidAppear(_:)),
                          of: viewController)
    replaceImplementation(#selector(viewController.viewWillDisappear(_:)),
                          with: #selector(viewController.keyboardLayoutGuide_viewWillDisappear(_:)),
                          of: viewController)
    replaceImplementation(#selector(viewController.viewDidDisappear(_:)),
                          with: #selector(viewController.keyboardLayoutGuide_viewDidDisappear(_:)),
                          of: viewController)
}

extension UIViewController {

    fileprivate var keyboardWillChangeFrameObserver: NSObjectProtocol? {
        get {
            return objc_getAssociatedObject(self, &keyboardWillChangeFrameObserverKey) as? NSObjectProtocol
        }
        set {
            objc_setAssociatedObject(self, &keyboardWillChangeFrameObserverKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    fileprivate var keyboardWillHideObserver: NSObjectProtocol? {
        get {
            return objc_getAssociatedObject(self, &keyboardWillHideObserverKey) as? NSObjectProtocol
        }
        set {
            objc_setAssociatedObject(self, &keyboardWillHideObserverKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    fileprivate var keyboardLayoutGuideConstraint: NSLayoutConstraint? {
        get {
            return objc_getAssociatedObject(self, &keyboardLayoutGuideConstraintKey) as? NSLayoutConstraint
        }
        set {
            objc_setAssociatedObject(self, &keyboardLayoutGuideConstraintKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    fileprivate var keyboardLayoutGuideAccessoryViewConstraint: NSLayoutConstraint? {
        get {
            return objc_getAssociatedObject(self, &keyboardLayoutGuideAccessoryViewConstraintKey) as? NSLayoutConstraint
        }
        set {
            objc_setAssociatedObject(self, &keyboardLayoutGuideAccessoryViewConstraintKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    fileprivate var keyboardLayoutGuideWillAppear: Bool {
        get {
            return objc_getAssociatedObject(self, &keyboardLayoutGuideWillAppearKey) as? Bool ?? false
        }
        set {
            objc_setAssociatedObject(self, &keyboardLayoutGuideWillAppearKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    fileprivate var keyboardLayoutGuideWillDisappear: Bool {
        get {
            return objc_getAssociatedObject(self, &keyboardLayoutGuideWillDisappearKey) as? Bool ?? false
        }
        set {
            objc_setAssociatedObject(self, &keyboardLayoutGuideWillDisappearKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    fileprivate static var keyboardLayoutGuideDidSwizzle = false

    private func keyboardLayoutGuide(createIfNil: Bool) -> UILayoutGuide? {
        let guide = objc_getAssociatedObject(self, &keyboardLayoutGuideKey) as? UILayoutGuide
        if guide == nil && createIfNil {
            if !UIViewController.keyboardLayoutGuideDidSwizzle {
                keyboardLayoutGuideSwizzling(UIViewController.self)
                UIViewController.keyboardLayoutGuideDidSwizzle = true
            }
            registerKeyboardObservers()

            let newGuide = UILayoutGuide()
            view.addLayoutGuide(newGuide)

            keyboardLayoutGuideConstraint = newGuide.topAnchor.constraint(equalTo: self.view.topAnchor, constant: self.view.frame.height)
            keyboardLayoutGuideConstraint?.priority = .defaultLow
            keyboardLayoutGuideConstraint?.isActive = true

            keyboardLayoutGuideAccessoryViewConstraint = newGuide.topAnchor.constraint(lessThanOrEqualTo: self.view.bottomAnchor, constant: 0)
            keyboardLayoutGuideAccessoryViewConstraint?.priority = .defaultHigh
            keyboardLayoutGuideAccessoryViewConstraint?.isActive = true

            newGuide.topAnchor.constraint(equalTo: view.bottomAnchor, constant: 0)
            newGuide.topAnchor.constraint(lessThanOrEqualTo: self.view.safeAreaLayoutGuide.bottomAnchor).isActive = true
            newGuide.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0).isActive = true
            newGuide.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 0).isActive = true
            newGuide.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: 0).isActive = true
            return newGuide
        }
        return guide
    }

    public var keyboardLayoutGuide: UILayoutGuide? {
        get {
            return keyboardLayoutGuide(createIfNil: true)
        }
    }

    @objc public func keyboardLayoutGuide_viewWillAppear(_ animated: Bool) {
        self.keyboardLayoutGuideWillAppear = true
        self.keyboardLayoutGuideWillDisappear = false
        keyboardLayoutGuide_viewWillAppear(animated)
    }

    @objc public func keyboardLayoutGuide_viewDidAppear(_ animated: Bool) {
        self.keyboardLayoutGuideWillAppear = false
        self.keyboardLayoutGuideWillDisappear = false
        keyboardLayoutGuide_viewDidAppear(animated)
        if keyboardLayoutGuide(createIfNil: false) != nil {
            registerKeyboardObservers()
        }
    }

    @objc public func keyboardLayoutGuide_viewWillDisappear(_ animated: Bool) {
        self.keyboardLayoutGuideWillAppear = false
        self.keyboardLayoutGuideWillDisappear = true
        keyboardLayoutGuide_viewWillDisappear(animated)
        if keyboardLayoutGuide(createIfNil: false) != nil {
            unregisterKeyboardObservers()
        }
    }

    @objc public func keyboardLayoutGuide_viewDidDisappear(_ animated: Bool) {
        self.keyboardLayoutGuideWillAppear = false
        self.keyboardLayoutGuideWillDisappear = false
        keyboardLayoutGuide_viewDidDisappear(animated)
    }

    func registerKeyboardObservers() {
        self.keyboardWillChangeFrameObserver = NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillChangeFrameNotification, object: nil, queue: nil, using: { [weak self] notification in
            //print("keyboard change \(payload.beginFrame) -> \(payload.endFrame) (\(payload.animationDuration))")
            self?.keyboardLayoutGuide_updateConstraints(keyboardIsVisible: true, notification: notification)
        })
        self.keyboardWillHideObserver = NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: nil, using: { [weak self] notification in
            // The hide event is needed when scrolling down the keyboard and drop it at the bottom (dont leave screen with finger)
            self?.keyboardLayoutGuide_updateConstraints(keyboardIsVisible: false, notification: notification)
        })
    }

    func unregisterKeyboardObservers() {
        if let observer = self.keyboardWillChangeFrameObserver {
            NotificationCenter.default.removeObserver(observer, name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        }
        if let observer = self.keyboardWillHideObserver {
            NotificationCenter.default.removeObserver(observer, name: UIResponder.keyboardWillHideNotification, object: nil)
        }
    }

    func keyboardLayoutGuide_updateConstraints(keyboardIsVisible: Bool, notification: Notification) {
        let beginFrame = notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as! CGRect
        let endFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as! CGRect
        let animationDuration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as! Double
        if keyboardIsVisible && endFrame.origin.y == beginFrame.origin.y {
            return
        }
        if self.keyboardLayoutGuideWillDisappear {
            return
        }
        if let constraint = keyboardLayoutGuideConstraint {
            self.view.setNeedsLayout()
            let point = self.view.convert(endFrame.origin, from: nil)
            constraint.constant = point.y
            if let firstResponder = UIResponder.first, let accessoryView = firstResponder.inputAccessoryView ?? firstResponder.inputAccessoryViewController?.view {
                self.keyboardLayoutGuideAccessoryViewConstraint?.constant = -accessoryView.frame.height
            }
            if !self.keyboardLayoutGuideWillAppear {
                if animationDuration > 0 {
                    self.view.layoutIfNeeded()
                }
            }
        }
    }

}

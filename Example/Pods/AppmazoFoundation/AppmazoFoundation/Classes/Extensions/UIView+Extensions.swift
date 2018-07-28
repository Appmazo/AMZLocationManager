//
//  UIView+Extensions.swift
//  AppmazoKit
//
//  Created by James Hickman on 5/18/18.
//  Copyright © 2018 Appmazo, LLC. All rights reserved.
//

import Foundation

public extension UIView {
    /**
     Adds the subview to the parent and attaches constraints to all edges.
     
     - parameters:
     - view: The subview to add.
     - usingSafeAreaGuide: Determines if the safeAreaGuide should be used if available.
     - belowView: The subview to insert below.
     - aboveView: The subview to insert above.
     - important:
     You should only set safeAreaGuide to true if the view is the outermost view of the view controller. Using safeAreaGuide with embedded views will cause problems. *(i.e. UIScrollView's content won't scroll)*
     */
    public func fillWithSubview(_ view: UIView, usingSafeAreaGuide: Bool = false, belowView: UIView? = nil, aboveView: UIView? = nil) {
        view.translatesAutoresizingMaskIntoConstraints = false
        
        if let belowView = belowView {
            insertSubview(view, belowSubview: belowView)
        } else if let aboveView = aboveView {
            insertSubview(view, aboveSubview: aboveView)
        } else {
            addSubview(view)
        }
        
        if #available(iOS 11, *), usingSafeAreaGuide {
            let guide = safeAreaLayoutGuide
            NSLayoutConstraint.activate([view.topAnchor.constraint(equalTo: guide.topAnchor)])
            NSLayoutConstraint.activate([view.bottomAnchor.constraint(equalTo: guide.bottomAnchor)])
            NSLayoutConstraint.activate([view.leftAnchor.constraint(equalTo: guide.leftAnchor)])
            NSLayoutConstraint.activate([view.rightAnchor.constraint(equalTo: guide.rightAnchor)])
        } else {
            let views = ["view": view]
            NSLayoutConstraint.activate(NSLayoutConstraint.constraints(withVisualFormat: "V:|[view]|", options: [], metrics: nil, views: views))
            NSLayoutConstraint.activate(NSLayoutConstraint.constraints(withVisualFormat: "|[view]|", options: [], metrics: nil, views: views))
        }
    }
    
    /**
     Adds the subview to the parent, and centers on another view.
     
     - parameters:
     - view: The view to add.
     - centeredView: The view to center on. It does not need to be the view's superview, but must be within the same superview.
     */
    public func addSubview(_ view: UIView, centeredWithView centeredView: UIView) {
        view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(view)
        
        NSLayoutConstraint(item: view, attribute: .centerX, relatedBy: .equal, toItem: centeredView, attribute: .centerX, multiplier: 1.0, constant: 0.0).isActive = true
        NSLayoutConstraint(item: view, attribute: .centerY, relatedBy: .equal, toItem: centeredView, attribute: .centerY, multiplier: 1.0, constant: 0.0).isActive = true
    }
    
    /**
     Shakes the view to signal an error to the user.
     */
    public func shake() {
        let midX = center.x
        let midY = center.y
        
        let animation = CABasicAnimation(keyPath: "position")
        animation.duration = 0.06
        animation.repeatCount = 4
        animation.autoreverses = true
        animation.fromValue = CGPoint(x: midX - 10.0, y: midY)
        animation.toValue = CGPoint(x: midX + 10.0, y: midY)
        layer.add(animation, forKey: "position")
    }
    
    /**
     Replaces the view with a centered UIActivityIndicatorView
     
     - parameters activityIndicatorStyle: The style for the UIActivityIndicatorView.
     */
    static var activityIndicatorView: UIActivityIndicatorView?
    public func replaceWithActivityIndicator(activityIndicatorStyle: UIActivityIndicatorViewStyle) {
        isHidden = true
        
        let activityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: activityIndicatorStyle)
        superview?.addSubview(activityIndicatorView, centeredWithView: self)
        activityIndicatorView.startAnimating()
        UIView.activityIndicatorView = activityIndicatorView
    }
    
    /**
     Hides the view's UIActivityIndicatorView.
     */
    public func hideActivityIndicator() {
        UIView.activityIndicatorView?.stopAnimating()
        UIView.activityIndicatorView?.removeFromSuperview()
        isHidden = false
    }
    
    /**
     Applies a corner radius that will also clip the view to the bounds.
     */
    public func roundCorners(withRadius radius: CGFloat) {
        layer.cornerRadius = radius
        clipsToBounds = true
    }
    
    /**
     Applies a corner radius that will clip the view as a circle.
     */
    public func cropAsCircle() {
        layer.cornerRadius = bounds.width / 2.0
        clipsToBounds = true
    }
    
    /**
     Adds a border with the provided width and color.
     - parameters
     - width: The width of the border.
     - color: The color of the border.
     */
    public func addBorder(withWidth width: CGFloat, color: UIColor) {
        layer.borderWidth = width
        layer.borderColor = color.cgColor
    }
    
    /**
     Removes the border.
     */
    public func removeBorder() {
        layer.borderWidth = 0.0
        layer.borderColor = UIColor.clear.cgColor
    }
    
    /**
     Sets the border color.
     */
    public var borderColor: UIColor? {
        get {
            return UIColor(cgColor: layer.borderColor!)
        }
        set {
            layer.borderColor = newValue?.cgColor
        }
    }
    
    /**
     Sets the left border width.
     */
    public var leftBorderWidth: CGFloat {
        get {
            return 0.0   // Just to satisfy property
        }
        set {
            let line = UIView(frame: CGRect(x: 0.0, y: 0.0, width: newValue, height: bounds.height))
            line.translatesAutoresizingMaskIntoConstraints = false
            line.backgroundColor = UIColor(cgColor: layer.borderColor!)
            self.addSubview(line)
            
            let views = ["line": line]
            let metrics = ["lineWidth": newValue]
            addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "|[line(==lineWidth)]", options: [], metrics: metrics, views: views))
            addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[line]|", options: [], metrics: nil, views: views))
        }
    }
    
    /**
     Sets the top border width.
     */
    public var topBorderWidth: CGFloat {
        get {
            return 0.0   // Just to satisfy property
        }
        set {
            let line = UIView(frame: CGRect(x: 0.0, y: 0.0, width: bounds.width, height: newValue))
            line.translatesAutoresizingMaskIntoConstraints = false
            line.backgroundColor = UIColor(cgColor: layer.borderColor!)
            self.addSubview(line)
            
            let views = ["line": line]
            let metrics = ["lineWidth": newValue]
            addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "|[line]|", options: [], metrics: nil, views: views))
            addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[line(==lineWidth)]", options: [], metrics: metrics, views: views))
        }
    }
    
    /**
     Sets the right border width.
     */
    public var rightBorderWidth: CGFloat {
        get {
            return 0.0   // Just to satisfy property
        }
        set {
            let line = UIView(frame: CGRect(x: bounds.width, y: 0.0, width: newValue, height: bounds.height))
            line.translatesAutoresizingMaskIntoConstraints = false
            line.backgroundColor = UIColor(cgColor: layer.borderColor!)
            self.addSubview(line)
            
            let views = ["line": line]
            let metrics = ["lineWidth": newValue]
            addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "[line(==lineWidth)]|", options: [], metrics: metrics, views: views))
            addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[line]|", options: [], metrics: nil, views: views))
        }
    }
    
    /**
     Sets the bottom border width.
     */
    public var bottomBorderWidth: CGFloat {
        get {
            return 0.0   // Just to satisfy property
        }
        set {
            let line = UIView(frame: CGRect(x: 0.0, y: bounds.height, width: bounds.width, height: newValue))
            line.translatesAutoresizingMaskIntoConstraints = false
            line.backgroundColor = UIColor(cgColor: layer.borderColor!)
            self.addSubview(line)
            
            let views = ["line": line]
            let metrics = ["lineWidth": newValue]
            addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "|[line]|", options: [], metrics: nil, views: views))
            addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[line(==lineWidth)]|", options: [], metrics: metrics, views: views))
        }
    }
}

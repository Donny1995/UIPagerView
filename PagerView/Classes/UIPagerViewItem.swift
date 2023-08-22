//
//  PagerViewItem.swift
//  UIComponents
//
//  Created by Sivash Alexander Alexeevich on 15.08.2023.
//

import UIKit

open class UIPagerViewItem: UIView {
    var cacheName: String?
    var index: Int = -1
    
    required public override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open func willDisplayView() { }
    open func didEndDisplayingView() { }
}

/// This is a basic cell, that can contain any view and position itself properly
///
/// containingView: view that is contained and added to cell
open class GenericUIPagerViewItem<T: UIView>: UIPagerViewItem {
    
    //MARK: - ❐ Variables
    public required init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open var contentInset: UIEdgeInsets = .zero {
        didSet {
            guard contentInset != oldValue else { return }
            _ = mViewContent
            contentTopConstraint?.constant =  contentInset.top
            contentLeadingConstraint?.constant =  contentInset.left
            contentTrailingConstraint?.constant = -contentInset.right
            contentBottomConstraint?.constant = -contentInset.bottom
            setNeedsLayout()
        }
    }
    
    var contentTopConstraint: NSLayoutConstraint?
    var contentLeadingConstraint: NSLayoutConstraint?
    var contentTrailingConstraint: NSLayoutConstraint?
    var contentBottomConstraint: NSLayoutConstraint?
    
    public lazy var mViewContent: T = { [unowned self] in
        let view = T.init(frame: bounds)
        view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(view)
        setNeedsUpdateConstraints()
        return view
    }()
    
    override open func updateConstraints() {
        NSLayoutConstraint.deactivate([
            contentTopConstraint,
            contentLeadingConstraint,
            contentTrailingConstraint,
            contentBottomConstraint,
        ].compactMap({ $0 }))
        
        contentTopConstraint = mViewContent.topAnchor.constraint(equalTo: mViewContent.superview!.topAnchor, constant: contentInset.top)
        contentLeadingConstraint = mViewContent.leadingAnchor.constraint(equalTo: mViewContent.superview!.leadingAnchor, constant: contentInset.left)
        contentTrailingConstraint = mViewContent.trailingAnchor.constraint(equalTo: mViewContent.superview!.trailingAnchor, constant: -contentInset.right)
        contentBottomConstraint = mViewContent.bottomAnchor.constraint(equalTo: mViewContent.superview!.bottomAnchor, constant: -contentInset.bottom)
        
        NSLayoutConstraint.activate([
            contentTopConstraint,
            contentLeadingConstraint,
            contentTrailingConstraint,
            contentBottomConstraint,
        ].compactMap({ $0 }))
        
        super.updateConstraints()
    }
}

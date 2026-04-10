//
//  PagerViewItem.swift
//  UIComponents
//
//  Created by Sivash Alexander Alexeevich on 15.08.2023.
//

import UIKit

open class UIPagerViewItem: UIView {
    var cacheName: String?
    ///Индекс, с которым этот айтем был призван на экран, если применимо
    public internal(set) var index: Int = -1
    
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
    public lazy var mViewContent: T = createContentView()
    
    private var layoutIsPrepared: Bool = false
    private var contentTopConstraint: NSLayoutConstraint?
    private var contentLeadingConstraint: NSLayoutConstraint?
    private var contentTrailingConstraint: NSLayoutConstraint?
    private var contentBottomConstraint: NSLayoutConstraint?
    
    open var contentInset: UIEdgeInsets = .zero {
        didSet {
            if contentInset != oldValue {
                setNeedsUpdateConstraints()
            }
        }
    }
    
    open func createContentView() -> T {
        return T.init(frame: bounds)
    }
    
    private func prepareLayoutIfNeeded() {
        guard !layoutIsPrepared else {
            return
        }
        
        mViewContent.translatesAutoresizingMaskIntoConstraints = false
        addSubview(mViewContent)
        contentTopConstraint = mViewContent.topAnchor.constraint(equalTo: topAnchor, constant: contentInset.top)
        contentLeadingConstraint = mViewContent.leadingAnchor.constraint(equalTo: leadingAnchor, constant: contentInset.left)
        contentTrailingConstraint = mViewContent.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -contentInset.right)
        contentBottomConstraint = mViewContent.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -contentInset.bottom)
     
        contentTopConstraint?.isActive = true
        contentLeadingConstraint?.isActive = true
        contentTrailingConstraint?.isActive = true
        contentBottomConstraint?.isActive = true
        
        layoutIsPrepared = true
    }
    
    override open func layoutSubviews() {
        prepareLayoutIfNeeded()
        super.layoutSubviews()
    }
    
    override open func updateConstraints() {
        prepareLayoutIfNeeded()
        contentTopConstraint?.constant =  contentInset.top
        contentLeadingConstraint?.constant =  contentInset.left
        contentTrailingConstraint?.constant = -contentInset.right
        contentBottomConstraint?.constant = -contentInset.bottom
        super.updateConstraints()
    }
}

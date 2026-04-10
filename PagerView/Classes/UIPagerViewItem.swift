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
        let view = T.init(frame: bounds)
        
        view.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(view)
        contentTopConstraint = view.topAnchor.constraint(equalTo: self.topAnchor, constant: contentInset.top)
        contentLeadingConstraint = view.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: contentInset.left)
        contentTrailingConstraint = view.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -contentInset.right)
        contentBottomConstraint = view.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -contentInset.bottom)
        
        return view
    }
    
    override open func updateConstraints() {
        _ = mViewContent
        contentTopConstraint?.constant =  contentInset.top
        contentLeadingConstraint?.constant =  contentInset.left
        contentTrailingConstraint?.constant = -contentInset.right
        contentBottomConstraint?.constant = -contentInset.bottom
        super.updateConstraints()
    }
}

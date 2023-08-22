//
//  MagicScrollView.swift
//  UIComponents
//
//  Created by Alexandr Sivash on 15.08.2023.
//

import Foundation
import UIKit

class MagicScrollView: UIScrollView {
    
    let axis: NSLayoutConstraint.Axis
    init(axis: NSLayoutConstraint.Axis, frame: CGRect) {
        self.axis = axis
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        switch axis {
        case .horizontal:
            return point.y >= 0 && point.y <= self.bounds.size.height
            
        case .vertical:
            return point.x >= 0 && point.x <= self.bounds.size.width
        }
    }
}

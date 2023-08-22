//
//  RandomAccessCollection + Range.swift
//  UIComponents
//
//  Created by Юрий Логинов on 15.08.2023.
//

import Foundation

extension RandomAccessCollection {
    
    func range(around: Index, leftDistance: Int, rightDistance: Int) -> ClosedRange<Index>? {
        guard
            !isEmpty, (startIndex..<endIndex).contains(around),
            let leftIndex = index(
                around,
                offsetBy: -Swift.min(self.distance(from: startIndex, to: around), Swift.max(0, leftDistance)),
                limitedBy: startIndex
            ),
            let rightIndex = index(
                around,
                offsetBy: Swift.min(self.distance(from: around, to: endIndex) - 1, Swift.max(0, rightDistance)),
                limitedBy: endIndex
            )
        else {
            return nil
        }
        
        return ClosedRange<Index>(uncheckedBounds: (
            lower: leftIndex,
            upper: rightIndex
        ))
    }
    
    func range(around: Index, distance: Int) -> ClosedRange<Index>? {
        return range(around: around, leftDistance: distance, rightDistance: distance)
    }
}

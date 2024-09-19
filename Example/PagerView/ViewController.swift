//
//  ViewController.swift
//  PagerView
//
//  Created by Donny1995 on 08/22/2023.
//  Copyright (c) 2023 Donny1995. All rights reserved.
//

import UIKit
import PagerView

public final class ViewController: UIViewController {
    
    var items: [String] = (0..<12).compactMap(String.init)
    let pager: UIPagerView = .init(axis: .horizontal, frame: .zero)
    var reloadTimer: Timer?
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white

        view.addSubview(pager)
        pager.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            pager.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            pager.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            pager.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            pager.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
        ])
        
        pager.backgroundColor = .lightGray
        pager.scrollView.backgroundColor = UIColor.darkGray.withAlphaComponent(0.2)
        
        pager.pageInsets = .init(top: 8, left: 8, bottom: 8, right: 8)
        pager.middleItemScaleFactor = 0.2
        pager.delegate = self
        pager.datasource = self
        pager.reloadData()
        
        //To see over bounds
        //pager.scrollView.layer.transform = CATransform3DMakeScale(0.45, 0.45, 1.0)
        //pager.scrollView.clipsToBounds = false
        //pager.scrollView.layer.masksToBounds = false
    }
}

extension ViewController: UIPagerViewDelegate, UIPagerViewDataSource {
    
    public func pagerView(_ pager: UIPagerView, didSelect view: UIPagerViewItem, at index: Int) {
        
    }
    
    public func pagerView(numberOfElementsInt pagerView: UIPagerView) -> Int {
        return items.count
    }
    
    public func pagerView(_ pagerView: UIPagerView, viewFor index: Int) -> UIPagerViewItem? {
        let contentView = pagerView.dequeueReusableView(viewClass: GenericUIPagerViewItem<UILabel>.self, for: index)
        contentView.mViewContent.textAlignment = .center
        contentView.mViewContent.numberOfLines = 0
        contentView.mViewContent.text = String(repeating: items[index], count: 1000)
        contentView.backgroundColor = [UIColor.gray, .red, .green, .blue, .cyan, .yellow, .magenta, .orange, .purple,].randomElement()!
        
        let gesture = UITapGestureRecognizer()
        contentView.gestureRecognizers = [gesture]
        gesture.addTarget(self, action: #selector(didTap))
        
        return contentView
    }
    
    @objc func didTap() {
        pager.performBatchUpdates {
            
            //test removes
            
            
//                items.remove(at: range.upperBound)
//                pager.deleteItem(at: range.upperBound, animated: true)
//
//                items.remove(at: range.lowerBound)
//                pager.deleteItem(at: range.lowerBound, animated: true)
            
//                guard let range = (0..<items.count).range(around: pagerView.selectedIndex, distance: 1) else {
//                    return
//                }
//
//                items.insert("x-1", at: pagerView.selectedIndex-1)
//                pager.insertItem(at: pagerView.selectedIndex-1, animated: true)
//
//                items.insert("x", at: pagerView.selectedIndex)
//                pager.insertItem(at: pagerView.selectedIndex, animated: true)
//
//                items.insert("x+1", at: pagerView.selectedIndex + 1)
//                pager.insertItem(at: pagerView.selectedIndex + 1, animated: true)
            
            var itemsCopy = items
            
            let r_index1 = (0..<itemsCopy.count).randomElement()!
            itemsCopy.remove(at: r_index1)
            
            let r_index2 = (0..<itemsCopy.count).randomElement()!
            itemsCopy.remove(at: r_index2)
            
            let i_index1 = (0..<itemsCopy.count).randomElement()!
            itemsCopy.insert(UUID().uuidString, at: i_index1)
            
            let i_index2 = (0..<itemsCopy.count).randomElement()!
            itemsCopy.insert(UUID().uuidString, at: i_index2)
            
            let difference = itemsCopy.difference(from: items)
            for element in difference.removals {
                guard case let .remove(offset, _, _) = element else {
                    continue
                }
                
                pager.deleteItem(at: offset, animated: true)
            }
            
            for element in difference.insertions {
                guard case let .insert(offset, _, _) = element else {
                    continue
                }
                
                pager.insertItem(at: offset, animated: true)
            }
            
            items = itemsCopy
            
//                for index in range {
//                    items.insert("\(index)|", at: index)
//                    pager.insertItem(at: index, animated: true)
//                }
            
//                items.insert(contentsOf: ["n-1", "n", "n+1"], at: range.lowerBound)
//                for index in range {
//                    pager.insertItem(at: index, animated: true)
//                }
        }
    }
}


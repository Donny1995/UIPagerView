//
//  UIPagerView.swift
//  UIComponents
//
//  Created by Sivash Alexander Alexeevich on 15.08.2023.
//

import UIKit

public protocol UIPagerViewDelegate: AnyObject {
    func pagerView(_ pager: UIPagerView, didSelect view: UIPagerViewItem, at index: Int)
}

public protocol UIPagerViewDataSource: AnyObject {
    func pagerView(numberOfElementsInt pagerView: UIPagerView) -> Int
    func pagerView(_ pagerView: UIPagerView, viewFor index: Int) -> UIPagerViewItem?
}

open class UIPagerView: UIView, UIScrollViewDelegate {
    
    public enum Axis {
        case horizontal
        case vertical
        
        var toNsLayoutAxis: NSLayoutConstraint.Axis {
            switch self {
            case .horizontal: return .horizontal
            case .vertical: return .vertical
            }
        }
    }
    
    enum ItemPositioning {
        case middle
        case outOfBounds
    }
    
    public let scrollView: UIScrollView
    public var scrollViewConstraints = [NSLayoutConstraint]()
    private var contentSizeConstraint: NSLayoutConstraint?
    let feedbackGenerator = UISelectionFeedbackGenerator()
    
    public init(axis: Axis, frame: CGRect) {
        self.axis = axis
        self.scrollView = ExtendedIntaractionAreaScrollView(
            axis: axis.toNsLayoutAxis,
            frame: .init(origin: .zero, size: frame.size)
        )
        
        switch axis {
        case .horizontal:
            originKeyPath = \.x
            sizeKeyPath = \.width
            
        case .vertical:
            originKeyPath = \.y
            sizeKeyPath = \.height
        }
        
        super.init(frame: frame)
        
        scrollView.clipsToBounds = false
        scrollView.layer.masksToBounds = false
        scrollView.isPagingEnabled = true
        scrollView.isDirectionalLockEnabled = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 1.0
        scrollView.delegate = self
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        
        addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        adjustScrollViewFrame(scaleFactor: middleItemScaleFactor)
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public weak var delegate: UIPagerViewDelegate?
    public weak var datasource: UIPagerViewDataSource?
    
    //MARK: - 📦 Params
    
    ///Ось, по которой происходит пэйджинг
    public let axis: Axis
    let originKeyPath: WritableKeyPath<CGPoint, CGFloat>
    let sizeKeyPath: WritableKeyPath<CGSize, CGFloat>
    
    ///Инсет каждой страницы от границ пйэджера
    public var pageInsets: UIEdgeInsets = .zero {
        didSet {
            guard pageInsets != oldValue, window != nil else { return }
            guard window != nil else { return }
            positionViews(forIndex: selectedIndex)
        }
    }
    
    private var _middleItemScaleFactor: CGFloat = 1.0
    ///Какую долю ширины/высоты занимает центральный элемент пэйджера. От 0.01 до 1.0. По умолчанию 1.0
    public var middleItemScaleFactor: CGFloat = 1.0 {
        didSet {
            let normalized = min(1.0, max(0.01, middleItemScaleFactor))
            guard normalized != oldValue else { return }
            
            _middleItemScaleFactor = middleItemScaleFactor
            
            adjustScrollViewFrame(scaleFactor: normalized)
            positionViews(forIndex: selectedIndex)
        }
    }
    
    //MARK: - 📦 Managing views
    var managedViews: [UIPagerViewItem] = []
    public func reloadData(selectedIndex: Int? = nil) {
        passiveReuseCache.removeAll()
        
        let numberOfElements = datasource?.pagerView(numberOfElementsInt: self) ?? 0
        adjustContentSize(number: numberOfElements)
        positionViews(forIndex: selectedIndex ?? self.selectedIndex)
        
        setSelected(index: selectedIndex ?? self.selectedIndex, animated: false)
    }
    
    func view(for index: Int) -> (view: UIPagerViewItem, index: Int)? {
        guard let index = managedViews.firstIndex(where: { $0.index == index }) else {
            return nil
        }
        
        return (managedViews[index], index)
    }
    
    ///Возвращяет максимально возможное видимое количество элементов слева и справа от центрального
    open func getCurrentVisibleIndexesBounds() -> (before: Int, after: Int) {
        let range: Int
        
        var numberOfElements = floor(bounds.size[keyPath: sizeKeyPath] / pageFrame(for: 0).size[keyPath: sizeKeyPath]) + 2
        range = max(1, Int((numberOfElements - 1) / 2.0))
        return (range, range)
    }
    
    private var currentNumberOfElements: Int = 0
    open private(set) var selectedIndex: Int = 0 {
        didSet {
            guard selectedIndex != oldValue else {
                return
            }
            
            guard selectedIndex >= 0 && selectedIndex < currentNumberOfElements else {
                return
            }
            
            let contentView: UIPagerViewItem
            if let view = view(for: selectedIndex)?.view {
                contentView = view
                
            } else {
                assertionFailure("pagingView: selected view has no content!")
                contentView = UIPagerViewItem()
            }
            
            delegate?.pagerView(self, didSelect: contentView, at: selectedIndex)
        }
    }
    
    public func setSelected(index: Int, animated: Bool) {
        //selectedIndex = index
        
        let newOffset = pageFrame(for: index).origin
        scrollView.setContentOffset(newOffset, animated: animated)
    }
    
    private func adjustContentSize(number: Int, force: Bool = false) {
        guard currentNumberOfElements != number || force else { return }
        
        currentNumberOfElements = number
        contentSizeConstraint?.isActive = false
        
        switch axis {
        case .horizontal:
            contentSizeConstraint = scrollView.contentLayoutGuide.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, multiplier: CGFloat(number))
            contentSizeConstraint?.isActive = true
            
        case .vertical:
            contentSizeConstraint = scrollView.contentLayoutGuide.heightAnchor.constraint(equalTo: scrollView.frameLayoutGuide.heightAnchor, multiplier: CGFloat(number))
            contentSizeConstraint?.isActive = true
        }
    }
    
    open func adjustScrollViewFrame(scaleFactor: CGFloat) {
        scrollViewConstraints.forEach { $0.isActive = false }
        
        let alongAxis: (NSLayoutDimension, NSLayoutDimension)
        let perpendicularAxis: (NSLayoutDimension, NSLayoutDimension)
        
        switch axis {
        case .horizontal:
            alongAxis = (scrollView.widthAnchor, scrollView.superview!.widthAnchor)
            perpendicularAxis = (scrollView.heightAnchor, scrollView.superview!.heightAnchor)
            
        case .vertical:
            alongAxis = (scrollView.heightAnchor, scrollView.superview!.heightAnchor)
            perpendicularAxis = (scrollView.widthAnchor, scrollView.superview!.widthAnchor)
        }
        
        let newConstraints: [NSLayoutConstraint] = [
            scrollView.centerXAnchor.constraint(equalTo: scrollView.superview!.centerXAnchor),
            scrollView.centerYAnchor.constraint(equalTo: scrollView.superview!.centerYAnchor),
            alongAxis.0.constraint(equalTo: alongAxis.1, multiplier: scaleFactor),
            perpendicularAxis.0.constraint(equalTo: perpendicularAxis.1),
        ]
        
        scrollViewConstraints = newConstraints
        NSLayoutConstraint.activate(newConstraints)
    }
    
    func positionViews(forIndex: Int, itemPositioning: ItemPositioning? = .none) {
        
        layoutIfNeeded()
        guard bounds.size[keyPath: sizeKeyPath] > 0 else {
            return
        }
        
        let visibleBounds = getCurrentVisibleIndexesBounds()
        guard currentNumberOfElements > 0, let visibleRange = (0..<currentNumberOfElements).range(around: forIndex, leftDistance: visibleBounds.before, rightDistance: visibleBounds.after) else {
            return
        }
        
        //Пройти по имеющимся, сравнить их индексы с индексами текущего видимого окна
        //Отправить в кэш тех, кто вне этого окна
        var indexCacheMap = [Int: UIPagerViewItem]()
        managedViews = managedViews.filter { itemView in
            if visibleRange.contains(itemView.index) {
                indexCacheMap[itemView.index] = itemView //for later faster access
                return true
                
            } else {
                cacheItemView(itemView: itemView)
                return false
            }
        }
        
        //Пойти по индксам видимого окна, создать объекты, если таковые требуются
        for itemIndex in visibleRange {
            if let existingViewForThisIndex = indexCacheMap[itemIndex] {
                //cool, the view is on it's place
                if itemPositioning == nil {
                    let desiredFrame = itemFrame(for: itemIndex)
                    if existingViewForThisIndex.frame != desiredFrame {
                        existingViewForThisIndex.frame = desiredFrame
                    }
                }
                
            } else {
                dequeueAndPositionView(for: itemIndex, itemPositioning: itemPositioning)
            }
        }
    }
    
    @discardableResult
    func dequeueAndPositionView(for index: Int, itemPositioning: ItemPositioning? = .none) -> UIPagerViewItem? {
        guard let newItemView = datasource?.pagerView(self, viewFor: index) else {
            return nil
        }
        
        newItemView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        newItemView.translatesAutoresizingMaskIntoConstraints = true
        
        newItemView.index = index
        managedViews.append(newItemView)
        scrollView.addSubview(newItemView)
        
        newItemView.frame = itemFrame(for: index)
        
        switch itemPositioning {
        case .none:
            break
            
        case .middle:
            newItemView.frame.origin[keyPath: originKeyPath] = itemFrame(for: selectedIndex).origin[keyPath: originKeyPath]
            
        case .outOfBounds:
            if index >= selectedIndex {
                newItemView.frame.origin[keyPath: originKeyPath] += bounds.size[keyPath: sizeKeyPath]
            } else {
                newItemView.frame.origin[keyPath: originKeyPath] -= bounds.size[keyPath: sizeKeyPath]
            }
        }
        
        newItemView.layoutIfNeeded()
        
        return newItemView
    }
    
    ///Фрейм страницы пэйджера
    func pageFrame(for index: Int) -> CGRect {
        switch axis {
        case .horizontal:
            return .init(
                origin: .init(x: scrollView.bounds.width * CGFloat(index), y: 0),
                size: scrollView.bounds.size
            )
            
        case .vertical:
            return .init(
                origin: .init(x: 0, y: scrollView.bounds.height * CGFloat(index)),
                size: scrollView.bounds.size
            )
        }
    }
    
    ///Фрейм конкретной вьюшки, с учетом инсетов
    func itemFrame(for index: Int) -> CGRect {
        return pageFrame(for: index).inset(by: pageInsets)
    }
    
    ///extracts cache-able view to cache
    private func cacheItemView(itemView: UIPagerViewItem) {
        
        itemView.removeFromSuperview()
        
        if usesReuseCache, let contentCacheName = itemView.cacheName {
            let visibleBounds = getCurrentVisibleIndexesBounds()
            let maximumVisibleItems = 1 + visibleBounds.before + visibleBounds.after
            guard(passiveReuseCache[contentCacheName]?.count ?? 0) <= maximumVisibleItems else {
                return
            }
            
            NSLayoutConstraint.deactivate(itemView.constraints.filter { $0.firstAttribute == .height || $0.firstAttribute == .width })
            passiveReuseCache[contentCacheName, default: []].append(itemView)
        }
    }
    
    //MARK: - 📦 Dequeing views
    var usesReuseCache = true
    private var passiveReuseCache = [String: [UIView]]()
    
    public func dequeueReusableView<T: UIPagerViewItem>(prefix: String? = nil, viewClass: T.Type, for index: Int) -> T {
        let newFrame = itemFrame(for: index)
        
        let cacheName = [prefix, NSStringFromClass(viewClass)].compactMap({ $0 }).joined(separator: "-")
        if usesReuseCache, let viewFromCache = passiveReuseCache[cacheName]?.popLast() as? T {
            viewFromCache.frame = newFrame
            return viewFromCache
            
        } else {
            let newView = T.init(frame: newFrame)
            newView.cacheName = cacheName
            return newView
        }
    }
    
    //MARK: - 📦 ScrollView Delegate
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        let offset: CGFloat
        let pageSize: CGFloat
        
        switch axis {
        case .horizontal:
            offset = scrollView.contentOffset.x
            pageSize = scrollView.bounds.width
            
        case .vertical:
            offset = scrollView.contentOffset.y
            pageSize = scrollView.bounds.height
        }
        
        guard pageSize > 0 else { return }
        
        let newCalculatedSelectedIndex: Int
        if offset <= 1.0 {
            newCalculatedSelectedIndex = 0
            
        } else {
            newCalculatedSelectedIndex = Int(round(offset / pageSize))
        }
        
        feedbackGenerator.prepare()
        
        guard selectedIndex != newCalculatedSelectedIndex else { return }
        positionViews(forIndex: newCalculatedSelectedIndex)
        selectedIndex = newCalculatedSelectedIndex
        feedbackGenerator.selectionChanged()
    }
    
    //MARK: - 📦 Dynamic updates
    
    /*
    open func insertItem(at index: Int, animated: Bool) {
        let pageSize = pageFrame(for: index).size
        var animationBlocks = [() -> Void]()
        
        currentNumberOfElements += 1
        adjustContentSize(number: currentNumberOfElements)
        scrollView.contentSize.height += pageSize.height
        
        positionViews(forIndex: min(max(0, currentNumberOfElements - 1), max(0, selectedIndex)))
        for visibleView in managedViews where visibleView.index >= index {
            visibleView.index += 1
            
            animationBlocks.append {
                visibleView.frame.origin.y += pageSize.height
            }
        }
        
        let itemView = view(for: index)?.view
        if animated {
            itemView?.alpha = 0.0
            animationBlocks.append {
                itemView?.alpha = 1.0
            }
        }
        
        if animated {
            UIView.animate(withDuration: 1/3) { [self] in
                animationBlocks.forEach { $0() }
                scrollView.layoutIfNeeded()
            }
            
        } else {
            animationBlocks.forEach { $0() }
            scrollView.layoutIfNeeded()
        }
    }
    
    open func deleteItem(at index: Int, animated: Bool) {
        let pageSize = pageFrame(for: index).size
        var animationBlocks = [() -> Void]()
        
        currentNumberOfElements -= 1
        adjustContentSize(number: currentNumberOfElements)
        scrollView.contentSize.height -= pageSize.height
        
        if let currentItemView = view(for: index) {
            managedViews.remove(at: currentItemView.index)
            cacheItemView(itemView: currentItemView.view)
        }
        
        
        positionViews(forIndex: min(max(0, currentNumberOfElements - 1), max(0, selectedIndex)))
        
        for visibleView in managedViews where visibleView.index >= index {
            visibleView.index -= 1
            
            animationBlocks.append {
                visibleView.frame.origin.y -= pageSize.height
            }
        }
        
        if animated {
            UIView.animate(withDuration: 1/3) { [self] in
                animationBlocks.forEach { $0() }
                positionViews(forIndex: selectedIndex)
                scrollView.layoutIfNeeded()
            }
            
        } else {
            animationBlocks.forEach { $0() }
            positionViews(forIndex: selectedIndex)
            scrollView.layoutIfNeeded()
        }
    }
    
    open func reloadItem(at index: Int, animated: Bool) {
        guard let itemView = view(for: index) else {
            return
        }
        
        guard let view = dequeueAndPositionView(for: index) else {
            return
        }
        
        if animated {
            UIView.transition(from: itemView.view, to: view, duration: 1/3, options: [.transitionCrossDissolve])
        }
        
        managedViews.remove(at: itemView.index)
        cacheItemView(itemView: itemView.view)
    }
    */
    
    open func insertItem(at index: Int, animated: Bool) {
        batchIsAnimated = batchIsAnimated || animated
        insertedIndexes.insert(index)
        if !isPerformingBatchUpdate {
            performBatchUpdates { }
        }
    }
    
    open func reloadItem(at index: Int, animated: Bool) {
        batchIsAnimated = batchIsAnimated || animated
        reloadedIndexes.insert(index)
        if !isPerformingBatchUpdate {
            performBatchUpdates { }
        }
    }
    
    open func deleteItem(at index: Int, animated: Bool) {
        batchIsAnimated = batchIsAnimated || animated
        removedIndexes.insert(index)
        if !isPerformingBatchUpdate {
            performBatchUpdates { }
        }
    }
    
    var batchIsAnimated: Bool = false
    var insertedIndexes: Set<Int> = []
    var removedIndexes: Set<Int> = []
    var reloadedIndexes: Set<Int> = []
    
    var isPerformingBatchUpdate: Bool = false
    open func performBatchUpdates(_ updates: (() -> Void), completion: ((Bool) -> Void)? = nil) {
        
        let pageSize: CGFloat = pageFrame(for: 0).size[keyPath: sizeKeyPath]
        var scrollContentOffsetDiff: CGFloat = 0.0
        
        var fadeInViews = Set<UIPagerViewItem>()
        var fadeOutViews = Set<UIPagerViewItem>()
        
        isPerformingBatchUpdate = true
        usesReuseCache = false
        updates()
        
        guard !(insertedIndexes.isEmpty && removedIndexes.isEmpty && reloadedIndexes.isEmpty) else {
            isPerformingBatchUpdate = false
            usesReuseCache = true
            completion?(true)
            return
        }
        
        let oldNumberOfElements = currentNumberOfElements
        
        //Removals
        managedViews = managedViews.filter { visibleView in
            
            let isRemoved = removedIndexes.contains(visibleView.index)
            if isRemoved {
                //currentNumberOfElements -= 1
                
                fadeOutViews.insert(visibleView)
                //cacheItemView(itemView: visibleView)
                
            } else {
                let shiftCount = removedIndexes.filter( { $0 < visibleView.index }).count
                if shiftCount > 0 {
                    visibleView.index -= shiftCount
                }
            }
            
            return !isRemoved
        }
        
        currentNumberOfElements -= removedIndexes.count
        
        for index in insertedIndexes.sorted() {
            
            currentNumberOfElements += 1
            
            for visibleView in managedViews where visibleView.index >= index {
                visibleView.index += 1
            }
            
            if let itemView = dequeueAndPositionView(for: index, itemPositioning: .middle) {
                fadeInViews.insert(itemView)
            }
        }
        
        let newSelectedIndex = min(max(0, currentNumberOfElements - 1), max(0, selectedIndex))
        scrollContentOffsetDiff -= CGFloat(removedIndexes.lazy.filter({ $0 <= newSelectedIndex }).count) * pageSize
        scrollContentOffsetDiff += CGFloat(insertedIndexes.lazy.filter({ $0 <= newSelectedIndex }).count) * pageSize
        
        //Reloads
        for index in reloadedIndexes.subtracting(insertedIndexes) {
            guard let currentItemView = view(for: index) else {
                return
            }
            
            guard let newView = dequeueAndPositionView(for: index) else {
                return
            }
            
            managedViews.remove(at: currentItemView.index)
            fadeOutViews.insert(currentItemView.view)
            
            fadeInViews.insert(newView)
        }
        
        //preposition views
        positionViews(forIndex: newSelectedIndex, itemPositioning: .outOfBounds)
        
        fadeInViews.forEach {
            $0.layer.zPosition = CGFloat(-1000 - $0.index)
            $0.alpha = 0.0
        }
        
        fadeOutViews.forEach {
            $0.isUserInteractionEnabled = false
            $0.layer.zPosition = CGFloat(-1000 - $0.index)
        }
        
        if selectedIndex != newSelectedIndex {
            selectedIndex = newSelectedIndex
        }
        
        UIView.animate(withDuration: 1/3) { [self] in
            
            if oldNumberOfElements != currentNumberOfElements {
                adjustContentSize(number: currentNumberOfElements, force: true)
                scrollView.contentSize[keyPath: sizeKeyPath] += CGFloat(currentNumberOfElements - oldNumberOfElements) * pageSize
            }
            
            scrollView.setNeedsLayout()
            scrollView.layoutIfNeeded()
            
            if scrollContentOffsetDiff != 0 {
                var scrollShift = scrollView.contentOffset
                scrollShift[keyPath: originKeyPath] += scrollContentOffsetDiff
                scrollView.setContentOffset(scrollShift, animated: false)
            }
            
            //position views
            positionViews(forIndex: selectedIndex)
            fadeInViews.forEach { $0.alpha = 1.0 }
            fadeOutViews.forEach { $0.alpha = 0.0 }
            
        } completion: { [self] success in
            fadeOutViews.forEach { $0.removeFromSuperview() }
            fadeInViews.forEach { $0.layer.zPosition = 0 }
            isPerformingBatchUpdate = false
            usesReuseCache = true
            completion?(success)
        }
        
        insertedIndexes.removeAll()
        removedIndexes.removeAll()
        reloadedIndexes.removeAll()
        batchIsAnimated = false
    }
}

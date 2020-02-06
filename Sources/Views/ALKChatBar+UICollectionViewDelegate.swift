//
//  ALKChatBar+UICollectionViewDelegate.swift
//  ApplozicSwift
//
//  Created by OldPig Chu on 25/11/2019.
//  Copyright © 2019 Applozic. All rights reserved.
//

import UIKit
import Foundation

extension ALKChatBar: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == self.mentionUserList {
            return self.mentionUserItems.count
        }else if collectionView == self.tagStockCodeList {
            return self.tagStockCodeItems.count
        }
        return 0
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView == self.mentionUserList {
            let _item = self.mentionUserItems[indexPath.item]
            return ALKChatBarTagUserListCollectionViewCell.calculateCellWidth(title: "@ \(_item.name)")
        }else if collectionView == self.tagStockCodeList {
            let _item = self.tagStockCodeItems[indexPath.item]
            return ALKChatBarTagStockCodeListCollectionViewCell.calculateCellWidth(title:_item.name)
        }
        return CGSize.zero
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        return CGSize.zero
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize.zero
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 10
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 10
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == self.mentionUserList {
            let _cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ALKChatBarTagUserListCollectionViewCell", for: indexPath) as! ALKChatBarTagUserListCollectionViewCell
            let _item = self.mentionUserItems[indexPath.item]
            _cell.index = indexPath
            _cell.delegate = self
            _cell.labTitle.text = "@ \(_item.name)"
            return _cell
        }else if collectionView == self.tagStockCodeList {
            let _cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ALKChatBarTagStockCodeListCollectionViewCell", for: indexPath) as! ALKChatBarTagStockCodeListCollectionViewCell
            let _item = self.tagStockCodeItems[indexPath.item]
            _cell.labTitle.text = _item.name
            _cell.index = indexPath
            return _cell
        }
        return UICollectionViewCell()
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == self.tagStockCodeList {
            let _item = self.tagStockCodeItems[indexPath.item]
            self.didClickedSearchStockCodeResultInList(code: _item.code, name: _item.name, lastSearchStockCodeInfo: self.lastSearchStockCodeInfo)
        }
    }
}

//MARK: - MentionUser
public class ALKChatBarMentionUserCollectionViewFlowLayout: UICollectionViewFlowLayout {
    
    public override init() {
        super.init()
        self.setUp()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setUp(){
        self.sectionInset = UIEdgeInsets(top: 7.5, left: 10, bottom: 7.5, right: 10)
        self.scrollDirection = .horizontal
        self.invalidateLayout(with: UICollectionViewFlowLayoutInvalidationContext())
    }
    
    override public func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        let layoutAttributes = super.layoutAttributesForElements(in: rect)!.map { $0.copy() as! UICollectionViewLayoutAttributes }
        
        // Filter attributes to compute only cell attributes
        let cellAttributes = layoutAttributes.filter({ $0.representedElementCategory == .cell })
        
        // only for
        var _totalSpaceUsed:CGFloat = 0.0
        let _defaultLeftSpace:CGFloat = 10.0
        for attribute in cellAttributes {
            let _frameX = _totalSpaceUsed + _defaultLeftSpace
            _totalSpaceUsed += _defaultLeftSpace + attribute.frame.size.width
            attribute.frame.origin.x = _frameX
            attribute.frame.origin.y = self.sectionInset.top
        }
        
        return layoutAttributes
    }
    
}

extension ALKChatBar: ALKChatBarTagUserListCollectionViewCellDelegate {
    func didItemCloseButtonClicked(index:IndexPath?) {
        if let _index = index {
            self.removeMentionUser(index: _index.item)
        }
    }
}

//MARK: - tag stock code
public class ALKChatBarTagStockCodeCollectionViewFlowLayout: UICollectionViewFlowLayout {
    
    public override init() {
        super.init()
        self.setUp()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setUp(){
        self.sectionInset = UIEdgeInsets(top: 7.5, left: 10, bottom: 7.5, right: 10)
        self.scrollDirection = .horizontal
        self.invalidateLayout(with: UICollectionViewFlowLayoutInvalidationContext())
    }
    
    override public func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        let layoutAttributes = super.layoutAttributesForElements(in: rect)!.map { $0.copy() as! UICollectionViewLayoutAttributes }
        
        // Filter attributes to compute only cell attributes
        let cellAttributes = layoutAttributes.filter({ $0.representedElementCategory == .cell })
        
        // only for
        var _totalSpaceUsed:CGFloat = 0.0
        let _defaultLeftSpace:CGFloat = 10.0
        for attribute in cellAttributes {
            let _frameX = _totalSpaceUsed + _defaultLeftSpace
            _totalSpaceUsed += _defaultLeftSpace + attribute.frame.size.width
            attribute.frame.origin.x = _frameX
            attribute.frame.origin.y = self.sectionInset.top
        }
        
        return layoutAttributes
    }
    
}


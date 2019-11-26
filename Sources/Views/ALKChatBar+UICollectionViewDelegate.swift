//
//  ALKChatBar+UICollectionViewDelegate.swift
//  ApplozicSwift
//
//  Created by OldPig Chu on 25/11/2019.
//  Copyright © 2019 Applozic. All rights reserved.
//

import UIKit
import Foundation

extension ALKChatBar: UICollectionViewDelegate, UICollectionViewDataSource {
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.mentionUserItems.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let _cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ALKChatBarTagUserListCollectionViewCell", for: indexPath) as? ALKChatBarTagUserListCollectionViewCell ?? ALKChatBarTagUserListCollectionViewCell()
        let _item = self.mentionUserItems[indexPath.item]
        _cell.index = indexPath
        _cell.delegate = self
        _cell.labTitle.text = "@ \(_item.name)"
        return _cell
    }
}

extension ALKChatBar: ALKChatBarTagUserListCollectionViewCellDelegate {
    func didItemCloseButtonClicked(index:IndexPath?) {
        if let _index = index {
            self.removeMentionUser(index: _index.item)
        }
    }
}

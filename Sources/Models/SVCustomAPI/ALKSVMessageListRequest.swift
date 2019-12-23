//
//  ALKSVMessageListRequest.swift
//  ApplozicSwift
//
//  Created by OldPig Chu on 21/10/2019.
//  Copyright © 2019 Applozic. All rights reserved.
//

import Foundation
import Applozic

class ALKSVMessageListRequest : MessageListRequest {
    public var orderBy:NSNumber = 1//desc
    public var userIds:[String] = []
    
    override func getParamString() -> String! {
        var _paramString = super.getParamString()
        _paramString?.append("&orderBy=\(orderBy)")
        if self.userIds.count > 0 {
            for userId in self.userIds {
                _paramString?.append("&userIds=\(userId)")
            }
        }
        return _paramString!
    }
    
}

//
//  ALKSVUserDefaultsControl.swift
//  ApplozicSwift
//
//  Created by OldPig Chu on 18/10/2019.
//  Copyright © 2019 Applozic. All rights reserved.
//

import Foundation

public class ALKSVUserDefaultsControl {
    
    public static let shared:ALKSVUserDefaultsControl = ALKSVUserDefaultsControl()
    
    //user default
    private func getUserDefaultsControl() -> UserDefaults?{
        return UserDefaults.init(suiteName: "group.com.svapplozic.share")
    }
    
    public func clearUserDefaultsWhenLogout(){
        self.removeLastReadMessageInfo()
    }
    
    //last message detail info
    func saveLastReadMessageInfo(chatGroupId:String, messageId:String, createTime:Int) {
        var _valueDict = getUserDefaultsControl()?.dictionary(forKey: "com.svapplozic.userdefault.Stockviva_lastReadMessageInfo") ?? [String:Any]()
        
        if let _value = _valueDict[chatGroupId] as? [String:Any] {
            //if the value is smaller than saved
            if let _storageCreateTime = _value["createTime"] as? Int,
                _storageCreateTime >= createTime {
               return
            }
        }
        //update info
        _valueDict[chatGroupId] = ["msgId":messageId, "createTime":createTime]
        getUserDefaultsControl()?.setValue(_valueDict, forKey: "com.svapplozic.userdefault.Stockviva_lastReadMessageInfo")
        getUserDefaultsControl()?.synchronize()
    }
    
    func getLastReadMessageInfo(chatGroupId:String) -> (messageId:String, createTime:Int)? {
         guard let _valueDict = getUserDefaultsControl()?.dictionary(forKey: "com.svapplozic.userdefault.Stockviva_lastReadMessageInfo"),
               let _value = _valueDict[chatGroupId] as? [String:Any],
               let _msgId = _value["msgId"] as? String,
               let _createTime = _value["createTime"] as? Int else {
                return nil
        }
        return (messageId:_msgId, createTime:_createTime)
    }
    
    func removeLastReadMessageInfo(){
        getUserDefaultsControl()?.removeObject(forKey: "com.svapplozic.userdefault.Stockviva_lastReadMessageInfo")
    }
    
}

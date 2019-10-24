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
        return UserDefaults.init(suiteName: "group.com.applozic.share")
    }
    
    func clearUserDefaultsWhenLogout(){
        self.removeLastReadMessageTime()
    }
    
    //unread message
    func saveLastReadMessageTime(chatGroupId:String, time:Int) {
        var _valueDict = getUserDefaultsControl()?.dictionary(forKey: "com.applozic.userdefault.Stockviva_lastReadMessageTime") ?? [String:Any]()
        //if the value is smaller than saved
        if let _value = _valueDict[chatGroupId] as? Int, _value >= time {
            return
        }
        _valueDict[chatGroupId] = time
        getUserDefaultsControl()?.setValue(_valueDict, forKey: "com.applozic.userdefault.Stockviva_lastReadMessageTime")
        getUserDefaultsControl()?.synchronize()
    }
    
    func getLastReadMessageTime(chatGroupId:String) -> Int? {
        if let _valueDict = getUserDefaultsControl()?.dictionary(forKey: "com.applozic.userdefault.Stockviva_lastReadMessageTime") {
            return _valueDict[chatGroupId] as? Int
        }
        return nil
    }
    
    func removeLastReadMessageTime(){
        getUserDefaultsControl()?.removeObject(forKey: "com.applozic.userdefault.Stockviva_lastReadMessageTime")
    }

}

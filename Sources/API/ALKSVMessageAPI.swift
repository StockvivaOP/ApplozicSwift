//
//  ALKSVMessageAPI.swift
//  ApplozicSwift
//
//  Created by OldPig Chu on 10/12/2019.
//  Copyright © 2019 Applozic. All rights reserved.
//

import Foundation
import Applozic

class ALKSVMessageAPI {
    
    class func deleteMessage(msgKey:String?, isDeleteForAll:Bool, completed:@escaping ((_ result:String?, _ error:Error?)->())) {
        guard let _msgKey = msgKey else {
            completed(nil, nil)
            return
        }
        
        let _apiUrlStr = ALUserDefaultsHandler.getBASEURL() + "/rest/ws/message/delete"
        let _apiParamStr = "key=" + _msgKey + "&deleteForAll=" + ( isDeleteForAll ? "true" : "false" )
        let _requestObj = ALRequestHandler.createGETRequest(withUrlString: _apiUrlStr, paramString: _apiParamStr)
        
        ALResponseHandler.processRequest(_requestObj, andTag: "DELETE_MESSAGE") { (resultJson, error) in
            if error != nil {
                completed(nil, error)
                return
            }
            completed( resultJson as? String , nil)
        }
    }
}

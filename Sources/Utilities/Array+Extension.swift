//
//  Array+Extension.swift
//  
//
//  Created by Mukesh Thawani on 04/05/17.
//  Copyright © 2017 Applozic. All rights reserved.
//

import Foundation

extension Array {

    func group<U: Hashable>(by key: (Iterator.Element) -> U) -> [U:[Iterator.Element]] {
        var categories: [U: [Iterator.Element]] = [:]
        for element in self {
            let key = key(element)
            if case nil = categories[key]?.append(element) {
                categories[key] = [element]
            }
        }
        return categories
    }

    func convertToJsonString() ->String? {
        var _resultJsonUtf8Str:String? = nil
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: self, options: [])
            _resultJsonUtf8Str = String(data: jsonData, encoding: String.Encoding.utf8)!
            NSLog("\(_resultJsonUtf8Str ?? "")")
        } catch {
            print(error.localizedDescription)
        }
        
        //replace special character
        let _replacingStrArray = ["&" : "\\u0026"]
        for replacingStrKey in _replacingStrArray.keys {
            _resultJsonUtf8Str = _resultJsonUtf8Str?.replacingOccurrences(of: replacingStrKey, with: _replacingStrArray[replacingStrKey]!)
        }
        return _resultJsonUtf8Str
    }
}

extension Array where Element: Equatable {

    // Remove first collection element that is equal to the given `object`:
    mutating func remove(object: Element) {
        if let index = index(of: object) {
            remove(at: index)
        }
    }

}

//
//  String+Extension.swift
//  ApplozicSwift
//
//  Created by Mukesh Thawani on 04/05/17.
//  Copyright © 2017 Applozic. All rights reserved.
//

import Foundation
import UIKit

// MARK: - Extension for String
//get char at index
extension String {
    subscript(idx: Int) -> Character {
        guard let strIdx = index(startIndex, offsetBy: idx, limitedBy: endIndex)
            else { fatalError("String index out of bounds") }
        return self[strIdx]
    }
    //let testStr:String = "12345"
    //print(testStr[2])
}

extension String {
    func isCompose(of word:String) -> Bool {
        return self.range(of: word, options: .literal) != nil ? true : false
    }
}

//get index of char
extension String {
    public func indexOfCharacter(char: Character) -> Int? {
        guard let range = range(of: String(char)) else {
            return nil
        }
        return distance(from: startIndex, to: range.lowerBound)
    }
}

//get w h
extension String {
    func rectWithConstrainedSize(_ size: CGSize, font: UIFont) -> CGRect {
        let boundingBox = self.boundingRect(with: size, options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: font], context: nil)
        return boundingBox
    }

    func evaluateStringWidth (textToEvaluate: String,fontSize:CGFloat) -> CGFloat {
        let font = UIFont.systemFont(ofSize: fontSize)
        let attributes = NSDictionary(object: font, forKey:NSAttributedString.Key.font as NSCopying)
        let sizeOfText = textToEvaluate.size(withAttributes: (attributes as! [NSAttributedString.Key : Any] as [NSAttributedString.Key : Any]))
        return sizeOfText.width
    }
}

extension String {

    func stripHTML() -> String {
        return self.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? self
    }

    func trim() -> String {
        return self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

extension String {
    func isValidEmail(email: String) -> Bool {
        let REGEX: String
        REGEX = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,6}"
        return NSPredicate(format: "SELF MATCHES %@", REGEX).evaluate(with: email)
    }
}

extension String {
    var data: Data {
        return Data(utf8)
    }
}


//MARK: - stockviva tag
extension String {
    public func chatGroupSVMessageGetStockCode() -> [String] {
        return ALKTextView.getStockCodeFrom(message: self)
    }
    
    public func scAlkReplaceSpecialKey(matchInfo:[(match:String, type:ALKConfiguration.ConversationMessageLinkType)]) -> String {
        let _replacingStrArray = ["$": "", "hk.":"",
                                  "(" : "", ")" : "", "\u{FF08}" : "", "\u{FF09}" : "", ".hk": "",
                                  "\u{FF10}" : "0","\u{FF11}" : "1","\u{FF12}" : "2","\u{FF13}" : "3",
                                  "\u{FF14}" : "4","\u{FF15}" : "5","\u{FF16}" : "6","\u{FF17}" : "7",
                                  "\u{FF18}" : "8","\u{FF19}" : "9"]
        var _tempMessage = self as NSString
        if _tempMessage.length > 0 {
            for matchItem in matchInfo {
                do{
                    var _offsetForReplaceStockCode = 0
                    let _regex = try NSRegularExpression(pattern:matchItem.match, options: NSRegularExpression.Options.caseInsensitive)
                    let _searchedTextList = _regex.matches(in: self, options: NSRegularExpression.MatchingOptions.reportCompletion, range: NSRange(location: 0, length: self.count))
                    for searchedItem in _searchedTextList {
                        guard let _rangeOfStr = Range(searchedItem.range, in: self) else { continue }
                        let _orgSearchedStr = String(self[_rangeOfStr])
                        var _searchedStr = _orgSearchedStr.lowercased().trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                        for replacingStrKey in _replacingStrArray.keys {
                            _searchedStr = _searchedStr.replacingOccurrences(of: replacingStrKey, with: _replacingStrArray[replacingStrKey]!)
                        }
                        //add link
                        switch matchItem.type {
                        case .stockCode:
                            if let _stockInfo = ALKConfiguration.delegateSystemInfoRequestDelegate?.verifyDetectedValueForSpecialLink(value: _searchedStr, type: matchItem.type) as? (code:String, name:String) {
                                let _searchItemStartIndexAdjust = _offsetForReplaceStockCode + searchedItem.range.location
                                
                                _tempMessage = _tempMessage.replacingOccurrences(of: _searchedStr, with: _stockInfo.name, options: .literal, range: NSMakeRange(_searchItemStartIndexAdjust, searchedItem.range.length)) as NSString
                                
                                _offsetForReplaceStockCode += _stockInfo.name.count - searchedItem.range.length
                            }
                        default:
                            break
                        }
                    }
                }catch {
                    
                }
            }
        }
        return _tempMessage as String
    }
}

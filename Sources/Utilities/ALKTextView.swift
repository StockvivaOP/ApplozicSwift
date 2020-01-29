//
//  ALKTextView.swift
//  ApplozicSwift
//
//  Created by Shivam Pokhriyal on 13/06/19.
//

import Foundation

/// This disables selection in UITextView.
/// https://stackoverflow.com/a/44878203/6671572
class ALKTextView: UITextView{

    override open func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        guard let pos = closestPosition(to: point) else { return false }
        guard let range = tokenizer.rangeEnclosingPosition(pos, with: .character, inDirection: .layout(.left)) else { return false }
        let startIndex = offset(from: beginningOfDocument, to: range.start)
        return attributedText.attribute(.link, at: startIndex, effectiveRange: nil) != nil
    }

    open override var canBecomeFirstResponder: Bool{
        return true
    }

}

//MARK: - stockviva tag
extension UITextView {
    open func addLink(message:String, matchInfo:[(match:String, type:ALKConfiguration.ConversationMessageLinkType)]){
        let _replacingStrArray = ["$": "", "hk.":"",
                                  "(" : "", ")" : "", "\u{FF08}" : "", "\u{FF09}" : "", ".hk": "",
                                  "\u{FF10}" : "0","\u{FF11}" : "1","\u{FF12}" : "2","\u{FF13}" : "3",
                                  "\u{FF14}" : "4","\u{FF15}" : "5","\u{FF16}" : "6","\u{FF17}" : "7",
                                  "\u{FF18}" : "8","\u{FF19}" : "9"]
        
        let _resultAttStr = NSMutableAttributedString(string: message)
        if message.count > 0 {
            for matchItem in matchInfo {
                do{
                    let _regex = try NSRegularExpression(pattern:matchItem.match, options: NSRegularExpression.Options.caseInsensitive)
                    let _searchedTextList = _regex.matches(in: message, options: NSRegularExpression.MatchingOptions.reportCompletion, range: NSRange(location: 0, length: message.count))
                    for searchedItem in _searchedTextList {
                        guard let _rangeOfStr = Range(searchedItem.range, in: message) else { continue }
                        let _orgSearchedStr = String(message[_rangeOfStr])
                        var _searchedStr = _orgSearchedStr.lowercased().trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                        for replacingStrKey in _replacingStrArray.keys {
                            _searchedStr = _searchedStr.replacingOccurrences(of: replacingStrKey, with: _replacingStrArray[replacingStrKey]!)
                        }
                        //add link
                        if let _formatValue = matchItem.type.getFormatedValue(value: _searchedStr),
                            let _url = matchItem.type.getURLLink(value: _formatValue ),
                            ALKConfiguration.delegateSystemInfoRequestDelegate?.verifyDetectedValueForSpecialLink(value: _searchedStr, type: matchItem.type) ?? true {
                            _resultAttStr.setAttributes([.link: _url], range: searchedItem.range)
                        }
                    }
                }catch {
                    
                }
            }
        }
        if let _fontStyle = self.font {
            _resultAttStr.addAttribute(NSAttributedString.Key.font, value: _fontStyle, range: NSMakeRange(0, message.count) )
        }
        self.linkTextAttributes = [.foregroundColor: UIColor.blue,
                                       .underlineStyle: NSUnderlineStyle.single.rawValue]
        self.attributedText = _resultAttStr
    }
}

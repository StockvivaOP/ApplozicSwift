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
        guard let _char = self.characterRange(at: point) else {
            return false
        }
        let startIndex = offset(from: beginningOfDocument, to: _char.start)
        return attributedText.attribute(.link, at: startIndex, effectiveRange: nil) != nil
        
//        guard let pos = closestPosition(to: point) { return false }
//        guard let range = tokenizer.rangeEnclosingPosition(pos, with: .character, inDirection: .layout(.left)) else { return false }
//        let startIndex = offset(from: beginningOfDocument, to: range.start)
//        return attributedText.attribute(.link, at: startIndex, effectiveRange: nil) != nil
    }

    open override var canBecomeFirstResponder: Bool{
        return true
    }
    
    public static func getStockCodeFrom(message:String) -> [String] {
        var _result:[String] = []
        let _replacingStrArray = ["$": "", "hk.":"",
                                  "(" : "", ")" : "", "\u{FF08}" : "", "\u{FF09}" : "", ".hk": "",
                                  "\u{FF10}" : "0","\u{FF11}" : "1","\u{FF12}" : "2","\u{FF13}" : "3",
                                  "\u{FF14}" : "4","\u{FF15}" : "5","\u{FF16}" : "6","\u{FF17}" : "7",
                                  "\u{FF18}" : "8","\u{FF19}" : "9"]
        if message.count > 0 {
            for matchItem in ALKConfiguration.specialLinkList {
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
                        //check value
                        switch matchItem.type {
                        case .stockCode:
                            if let _stockInfo = ALKConfiguration.delegateSystemInfoRequestDelegate?.verifyDetectedValueForSpecialLink(value: _searchedStr, type: matchItem.type) as? (code:String, name:String) {
                                _result.append(_stockInfo.code)
                            }
                        default:
                            //none
                            break
                        }
                    }
                }catch {
                }
            }
        }
        
        return _result
    }
}

//MARK: - stockviva tag
extension UITextView {
    open func addLink(message:String, font:UIFont?, matchInfo:[(match:String, type:ALKConfiguration.ConversationMessageLinkType)]){
        let _replacingStrArray = ["$": "", "hk.":"",
                                  "(" : "", ")" : "", "\u{FF08}" : "", "\u{FF09}" : "", ".hk": "",
                                  "\u{FF10}" : "0","\u{FF11}" : "1","\u{FF12}" : "2","\u{FF13}" : "3",
                                  "\u{FF14}" : "4","\u{FF15}" : "5","\u{FF16}" : "6","\u{FF17}" : "7",
                                  "\u{FF18}" : "8","\u{FF19}" : "9"]
        var _defaultAtt:[NSAttributedString.Key : Any] = [:]
        let _contentStyle = NSMutableParagraphStyle()
        _contentStyle.lineSpacing = 2
        _defaultAtt[.paragraphStyle] = _contentStyle
        if let _fontStyle = font {
            _defaultAtt[NSAttributedString.Key.font] = _fontStyle
        }
        
        let _resultAttStr = NSMutableAttributedString(string: message, attributes: _defaultAtt)
        self.linkTextAttributes = [.foregroundColor: UIColor.blue,
                                   .underlineStyle: NSUnderlineStyle.single.rawValue]
        
        if message.count > 0 {
            for matchItem in matchInfo {
                do{
                    var _offsetForReplaceStockCode = 0
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
                            let _url = matchItem.type.getURLLink(value: _formatValue ){
                            switch matchItem.type {
                            case .stockCode:
                                if let _stockInfo = ALKConfiguration.delegateSystemInfoRequestDelegate?.verifyDetectedValueForSpecialLink(value: _searchedStr, type: matchItem.type) as? (code:String, name:String) {
                                    let _searchItemStartIndexAdjust = _offsetForReplaceStockCode + searchedItem.range.location
                                    _resultAttStr.replaceCharacters(in: NSMakeRange(_searchItemStartIndexAdjust, searchedItem.range.length), with: _stockInfo.name)
                                    _resultAttStr.addAttribute(.link, value: _url, range: NSMakeRange(_searchItemStartIndexAdjust, _stockInfo.name.count) )
                                    //set font for link
                                    if let _fontStyle = font {
                                        _resultAttStr.addAttribute(NSAttributedString.Key.font, value: _fontStyle, range: NSMakeRange(_searchItemStartIndexAdjust, _stockInfo.name.count) )
                                    }
                                    _offsetForReplaceStockCode += _stockInfo.name.count - searchedItem.range.length
                                }
                            default:
                                _resultAttStr.addAttribute(.link, value: _url, range: searchedItem.range )
                                //set font for link
                                if let _fontStyle = font {
                                    _resultAttStr.addAttribute(NSAttributedString.Key.font, value: _fontStyle, range: searchedItem.range )
                                }
                            }
                        }
                    }
                }catch {
                    
                }
            }
        }
        
        self.attributedText = _resultAttStr
    }
}

//
//  Date+Extension.swift
//  
//
//  Created by Mukesh Thawani on 04/05/17.
//  Copyright © 2017 Applozic. All rights reserved.
//

import Foundation

extension Date {

    /**
    @abstract Example - Assuming today is Friday 20 September 2017, we would show:
    Today, Yesterday, Wednesday, Tuesday, Monday, Sunday, Fri, Feb 24, Jun 3, 2016 (for previous year), Etc.
     */
    func stringCompareCurrentDate(showTodayTime: Bool = false) -> String {
        let calendar: Calendar = Calendar.current
        let toDate: Date = calendar.startOfDay(for: Date())
        let fromDate: Date = calendar.startOfDay(for: self)
        let unitFlags: Set<Calendar.Component> = [.day]
        let differenceDateComponent: DateComponents = calendar.dateComponents(unitFlags, from: fromDate, to: toDate)

        guard let day = differenceDateComponent.day else {
            return ""
        }

        let dateFormatter = DateFormatter()
        
        //set locale name
        if let _localeName = ALKConfiguration.delegateSystemInfoRequestDelegate?.getSystemLocaleName() {
            let _locale = Locale(identifier: _localeName)
            dateFormatter.locale = _locale
        }

        if showTodayTime && day == 0 {
            let dateFormat = DateFormatter.dateFormat(fromTemplate: "HH:mm", options: 0, locale: Locale.current)
            dateFormatter.dateFormat = dateFormat
        } else if day < 2 {
            dateFormatter.dateStyle = .medium
            dateFormatter.doesRelativeDateFormatting = true
        } else {
            let fromTemplate = (day < 7 ? "EEEE" : "EdMMM")
            let dateFormat = DateFormatter.dateFormat(fromTemplate: fromTemplate, options: 0, locale: Locale.current)
            dateFormatter.dateFormat = dateFormat
        }

        return dateFormatter.string(from: self)
    }

    func toHHmmMMMddFormat() -> String {
        let _dateFormatter = DateFormatter()
        _dateFormatter.dateFormat = "HH:mm MMMdd"
        //set locale name
        var _isChineseFormat = false
        if let _localeName = ALKConfiguration.delegateSystemInfoRequestDelegate?.getSystemLocaleName() {
            let _locale = Locale(identifier: _localeName)
            _dateFormatter.locale = _locale
            _isChineseFormat = _localeName.lowercased().starts(with: "zh_")
        }else{
            _dateFormatter.locale = Locale.current
        }
        
        var _dateStr = _dateFormatter.string(from: self)
        if _isChineseFormat {
            _dateStr = _dateStr + (ALKConfiguration.delegateSystemInfoRequestDelegate?.getSystemTextLocalizable(key: "unit_day") ?? "")
        }
        return _dateStr
    }
    
    func toConversationViewDateFormat() -> String {
        var _dayStr:String? = nil
        if let fromDate = Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: self),
            let toDate = Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: Date()) {
            let _components = Calendar.current.dateComponents([.day, .second], from: fromDate, to: toDate)
            if let _numOfDay = _components.day, _numOfDay >= 0 && _numOfDay <= 1 {
                if _numOfDay == 1 {
                    _dayStr = ALKConfiguration.delegateSystemInfoRequestDelegate?.getSystemTextLocalizable(key: "unit_yesterday")
                }else{
                    _dayStr = ALKConfiguration.delegateSystemInfoRequestDelegate?.getSystemTextLocalizable(key: "unit_today")
                }
            }
        }
        
        let _dateFormatter = DateFormatter()
        //set locale name
        var _isChineseFormat = false
        if let _localeName = ALKConfiguration.delegateSystemInfoRequestDelegate?.getSystemLocaleName() {
            let _locale = Locale(identifier: _localeName)
            _dateFormatter.locale = _locale
            _isChineseFormat = _localeName.lowercased().starts(with: "zh_")
        }else{
            _dateFormatter.locale = Locale.current
        }
        
        var _dateStr:String = ""
        if let _dayHumanStr = _dayStr {
            _dateFormatter.dateFormat = "HH:mm"
            _dateStr = _dateFormatter.string(from: self)
            _dateStr = _dateStr + " " + _dayHumanStr
        }else{
            _dateFormatter.dateFormat = "HH:mm MMMdd"
            _dateStr = _dateFormatter.string(from: self)
            
            if _isChineseFormat {
                _dateStr = _dateStr + (ALKConfiguration.delegateSystemInfoRequestDelegate?.getSystemTextLocalizable(key: "unit_day") ?? "")
            }
        }
        
        return _dateStr
    }
}

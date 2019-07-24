//
//  Int+Extension.swift
//  ApplozicSwift
//
//  Created by Shivam Pokhriyal on 23/07/19.
//

import Foundation

extension Int64 {
    func degree(outOf total: Int64) -> Double {
        let divergence = Double(total)/360.0
        let degree = Double(self)/divergence
        return degree
    }
}

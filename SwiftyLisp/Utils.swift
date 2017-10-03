//
//  Utils.swift
//  SwiftyLisp
//
//  Created by Bradley Slayter on 10/2/17.
//  Copyright © 2017 Bradley Slayter. All rights reserved.
//

import Foundation

extension String {
    func stripEscapeChars() -> String {
        var newStr = self.replacingOccurrences(of: "\n", with: " ")
        newStr = newStr.replacingOccurrences(of: "\t", with: "")
        
        return newStr
    }
}

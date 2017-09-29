//
//  main.swift
//  SwiftyLisp
//
//  Created by Bradley Slayter on 9/29/17.
//  Copyright © 2017 Bradley Slayter. All rights reserved.
//

import Foundation

let expr: Expr = "(cond ((atom (quote A)) (quote B)) ((quote true) (quote C)))"

var exit = false

while !exit {
    print(">>>", terminator: " ")
    let input = readLine(strippingNewline: true)
    exit = (input == "exit")
    
    if !exit {
        let e = Expr.read(input!)
        print(e.eval()!)
    }
}

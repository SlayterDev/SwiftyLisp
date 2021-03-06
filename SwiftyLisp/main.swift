//
//  main.swift
//  SwiftyLisp
//
//  Created by Bradley Slayter on 9/29/17.
//  Copyright © 2017 Bradley Slayter. All rights reserved.
//

import Foundation

let expr: Expr = "(cond ((atom (quote A)) (quote B)) ((quote true) (quote C)))"

if CommandLine.arguments.count > 1 {
    if let fileContents = try? String(contentsOfFile: CommandLine.arguments[1], encoding: .utf8) {
        let e = Expr.read("(" + fileContents.stripEscapeChars() + ")")
        print(e.eval()!)
    } else {
        print("[-] Could not read file: \(CommandLine.arguments[1])")
    }
}

var exit = false

while !exit {
    print(">>>", terminator: " ")
    let input = readLine(strippingNewline: true)
    exit = (input == "exit")
    
    if !exit {
        let e = Expr.read(input ?? "")
        print(e.eval()!)
    }
}

//
//  Model.swift
//  SwiftyLisp
//
//  Created by Bradley Slayter on 9/29/17.
//  Copyright © 2017 Bradley Slayter. All rights reserved.
//

import Foundation

public enum Expr {
    case atom(String)
    case list([Expr])
}

extension Expr: Equatable {
    public static func == (lhs: Expr, rhs: Expr) -> Bool {
        switch (lhs, rhs) {
        case let (.atom(l), .atom(r)):
            return l == r
        case let (.list(l), .list(r)):
            guard l.count == r.count else { return false }
            
            for (i, el) in l.enumerated() {
                if el != r[i] {
                    return false
                }
            }
            
            return true
        default:
            return false
        }
    }
}

extension Expr: CustomStringConvertible {
    public var description: String {
        switch self {
        case let .atom(val):
            return "\(val)"
        case let .list(subExprs):
            var res = "("
            subExprs.forEach { res += "\($0) " }
            if res.count > 1 { // Empty list would be just one char
                res = String(res.dropLast())
            }
            res += ")"
            return res
        }
    }
}

extension Expr {
    public static func read(_ expr: String) -> Expr {
        enum Token {
            case pOpen, pClose, textBlock(String)
        }
        
        func tokenize(_ expr: String) -> [Token] {
            var res = [Token]()
            var tempText = ""
            
            for c in expr {
                switch c {
                case "(":
                    if tempText != "" {
                        res.append(.textBlock(tempText))
                        tempText = ""
                    }
                    res.append(.pOpen)
                    
                case ")":
                    if tempText != "" {
                        res.append(.textBlock(tempText))
                        tempText = ""
                    }
                    res.append(.pClose)
                    
                case " ":
                    if tempText != "" {
                        res.append(.textBlock(tempText))
                        tempText = ""
                    }
                    
                default:
                    tempText.append(c)
                }
            }
            
            return res
        }
        
        func appendTo(list: Expr?, node: Expr) -> Expr {
            var list = list
            
            if list != nil, case var .list(elements) = list! {
                elements.append(node)
                list = .list(elements)
            } else {
                list = node
            }
            
            return list!
        }
        
        func parse(_ tokens: [Token], node: Expr? = nil) -> (remaining: [Token], subexpr: Expr?) {
            var tokens = tokens
            var node = node
            
            var i = 0
            repeat {
                let t = tokens[i]
                
                switch t {
                case .pOpen:
                    // new expr
                    let (tr, n) = parse(Array(tokens[(i + 1)..<tokens.count]), node: .list([]))
                    assert(n != nil)
                    
                    (tokens, i) = (tr, 0)
                    node = appendTo(list: node, node: n!)
                    
                    if tokens.count != 0 {
                        continue
                    } else {
                        break
                    }
                    
                case .pClose:
                    // close expr
                    return (Array(tokens[(i + 1)..<tokens.count]), node)
                    
                
                case .textBlock(let val):
                    node = appendTo(list: node, node: .atom(val))
                }
                
                i += 1
            } while (tokens.count > 0)
            
            return ([], node)
        }
        
        let tokens = tokenize(expr)
        let res = parse(tokens)
        return res.subexpr ?? .list([])
    }
}

extension Expr: ExpressibleByStringLiteral,
                ExpressibleByUnicodeScalarLiteral,
                ExpressibleByExtendedGraphemeClusterLiteral {
    public init(stringLiteral value: String) {
        self = Expr.read(value)
    }
    
    public init(extendedGraphemeClusterLiteral value: String){
        self.init(stringLiteral: value)
    }
    
    public init(unicodeScalarLiteral value: String){
        self.init(stringLiteral: value)
    }
}


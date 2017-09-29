//
//  Evaluation.swift
//  SwiftyLisp
//
//  Created by Bradley Slayter on 9/29/17.
//  Copyright © 2017 Bradley Slayter. All rights reserved.
//

import Foundation

func += <K, V> (left: inout [K: V], right: [K: V]) {
    right.forEach { left[$0.key] = $0.value }
}

public typealias LispFunc = (Expr, [Expr]?, [Expr]?) -> Expr

fileprivate enum Builtins: String {
    case quote, car, cdr, cons, equal, atom, cond, lambda, defun, list, println, eval
    
    public static func mustSkip(_ atom: String) -> Bool {
        return (atom == Builtins.quote.rawValue) ||
                (atom == Builtins.cond.rawValue) ||
                (atom == Builtins.lambda.rawValue) ||
                (atom == Builtins.defun.rawValue)
    }
}

private var defaultEnvironment: [String: LispFunc] = {
    var env = [String: LispFunc]()
    
    env[Builtins.quote.rawValue] = { params, locals, values in
        guard case let .list(parameters) = params, parameters.count == 2 else { return .list([]) }
        return parameters[1]
    }
    
    env[Builtins.car.rawValue] = { params, locals, values in
        guard case let .list(parameters) = params, parameters.count == 2 else { return .list([]) }
        guard case let .list(elements) = parameters[1], elements.count > 0 else { return .list([]) }
        
        return elements.first!
    }
    
    env[Builtins.cdr.rawValue] = { params, locals, values in
        guard case let .list(parameters) = params, parameters.count == 2 else { return .list([]) }
        guard case let .list(elements) = parameters[1], elements.count > 1 else { return .list([]) }
        
        return .list(Array(elements.dropFirst(1)))
    }
    
    env[Builtins.cons.rawValue] = { params, locals, values in
        guard case let .list(parameters) = params, parameters.count == 3 else { return .list([]) }
        guard case let .list(elements) = parameters[2] else { return .list([]) } // ensure second param is a list
        
        var res = [parameters[1]]
        elements.forEach { res.append($0) }
        
        return .list(res)
    }
    
    env[Builtins.equal.rawValue] = { params, locals, values in
        guard case let .list(elements) = params, elements.count == 3 else { return .list([]) }
    
        var me = env[Builtins.equal.rawValue]!
        
        switch (elements[1].eval(with: locals, for: values)!, elements[2].eval(with: locals, for: values)!) {
        case (.atom(let elLeft), .atom(let elRight)):
            return elLeft == elRight ? .atom("true") : .list([])
        case (.list(let elLeft), .list(let elRight)):
            guard elLeft.count == elRight.count else { return .list([]) }
            for (i, el) in elLeft.enumerated() {
                let testeq: [Expr] = [.atom("equal"), el, elRight[i]]
                if me(.list(testeq), locals, values) != .atom("true") {
                    return .list([])
                }
            }
            
            return .atom("true")
        default:
            return .list([])
        }
    }
    
    env[Builtins.atom.rawValue] = { params, locals, values in
        guard case let .list(parameters) = params, parameters.count == 2 else { return .list([]) }
        
        switch parameters[1].eval(with: locals, for: values)! {
        case .atom:
            return .atom("true")
        default:
            return .list([])
        }
    }
    
    env[Builtins.cond.rawValue] = { params, locals, values in
        guard case let .list(parameters) = params, parameters.count > 1 else { return .list([]) }
        
        for el in parameters.dropFirst(1) {
            guard case let .list(c) = el, c.count == 2 else { return .list([]) }
            
            if c[0].eval(with: locals, for: values) != .list([]) {
                let res = c[1].eval(with: locals, for: values)
                return res!
            }
        }
        
        return .list([])
    }
    
    env[Builtins.defun.rawValue] = { params, locals, values in
        guard case let .list(parameters) = params, parameters.count == 4 else { return .list([]) }
        
        guard case let .atom(lname) = parameters[1] else { return .list([]) }
        guard case let .list(vars) = parameters[2] else { return .list([]) }
        
        let lambda = parameters[3]
        
        let f: LispFunc = { params, locals, values in
            guard case var .list(p) = params else { return .list([]) }
            p = Array(p.dropFirst(1))
            
            if let result = lambda.eval(with: vars, for: p) {
                return result
            } else {
                return .list([])
            }
        }
        
        localContext[lname] = f
        return .list([])
    }
    
    env[Builtins.lambda.rawValue] = { params, locals, values in
        guard case let .list(parameters) = params, parameters.count == 3 else { return .list([]) }
        
        let lname = "lambda$" + String(arc4random_uniform(.max))
        guard case let .list(vars) = parameters[2] else { return .list([]) }
        
        let lambda = parameters[2]
        
        let f: LispFunc = { params, locals, values in
            guard case var .list(p) = params else { return .list([]) }
            p = Array(p.dropFirst(1))
            
            if let result = lambda.eval(with: vars, for: p) {
                return result
            } else {
                return .list([])
            }
        }
        
        localContext[lname] = f
        return .atom(lname)
    }
    
    env[Builtins.list.rawValue] = { params, locals, values in
        guard case let .list(parameters) = params, parameters.count > 1 else { return .list([]) }
        var res = [Expr]()
        
        for el in parameters.dropFirst(1) {
            switch el {
            case .atom:
                res.append(el)
            case .list(let els):
                res.append(contentsOf: els)
            }
        }
        
        return .list(res)
    }
    
    env[Builtins.println.rawValue] = { params, locals, values in
        guard case let .list(parameters) = params, parameters.count > 1 else { return .list([]) }
        
        print(parameters[1].eval(with: locals, for: values)!)
        return .list([])
    }
    
    env[Builtins.eval.rawValue] = { params, locals, values in
        guard case let .list(parameters) = params, parameters.count > 2 else { return .list([]) }
        
        return parameters[1].eval(with: locals, for: values)!
    }
    
    return env
}()

private var mathFunctions: [String: LispFunc] = {
    var env = [String: LispFunc]()
    
    func performMathOperation(_ elems: [Expr], op: (inout Int, Int) -> Void) -> Expr {
        guard case let .atom(strVal) = elems[0], var res = Int(strVal) else { return .list([]) }
        for el in elems[1..<elems.count] {
            guard case let .atom(strVal) = el, let intVal = Int(strVal) else { return .list([]) }
            
            op(&res, intVal)
        }
        
        return .atom("\(res)")
    }
    
    env["+"] = { params, locals, values in
        guard case let .list(parameters) = params, parameters.count > 2 else { return .list([]) }
        
        let elems = parameters.dropFirst().map { $0.eval(with: locals, for: values)! }
        
        return performMathOperation(elems, op: +=)
    }
    
    env["-"] = { params, locals, values in
        guard case let .list(parameters) = params, parameters.count > 2 else { return .list([]) }
        
        let elems = parameters.dropFirst().map { $0.eval(with: locals, for: values)! }
        
        return performMathOperation(elems, op: -=)
    }
    
    env["*"] = { params, locals, values in
        guard case let .list(parameters) = params, parameters.count > 2 else { return .list([]) }
        
        let elems = parameters.dropFirst().map { $0.eval(with: locals, for: values)! }
        
        return performMathOperation(elems, op: *=)
    }
    
    env["/"] = { params, locals, values in
        guard case let .list(parameters) = params, parameters.count > 2 else { return .list([]) }
        
        let elems = parameters.dropFirst().map { $0.eval(with: locals, for: values)! }
        
        return performMathOperation(elems, op: /=)
    }
    
    return env
}()

public var localContext = [String: LispFunc]()

extension Expr {
    func eval(with locals: [Expr]? = nil, for values: [Expr]? = nil) -> Expr? {
        var node = self
        
        switch node {
        case .atom:
            return evaluateVariable(node, with: locals, for: values)
        case .list(var elements):
            var skip = false
            
            if elements.count > 1, case let .atom(val) = elements[0] {
                skip = Builtins.mustSkip(val)
            }
            
            if !skip {
                elements = elements.map {
                    return $0.eval(with: locals, for: values)!
                }
            }
            node = .list(elements)
            
            if elements.count > 0, case let .atom(val) = elements[0],
                let f = localContext[val] ?? mathFunctions[val] ?? defaultEnvironment[val] {
                let r = f(node, locals, values)
                return r
            }
            
            return node
        }
    }
    
    func evaluateVariable(_ v: Expr, with locals: [Expr]?, for values: [Expr]?) -> Expr {
        guard let locals = locals, let values = values else { return v }
        
        if locals.contains(v) {
            return values[locals.index(of: v)!]
        } else {
            return v
        }
    }
}

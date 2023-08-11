//
//  Operator.swift
//  
//
//  Created by wes on 8/11/23.
//

typealias Precedence = Int

enum Operator: Int, CustomStringConvertible {
    case notEqual
    case equal
    case lt
    case ltOrEq
    case gt
    case gtOrEq
    case plus
    case minus
    case divide
    case multiply
    
    init?(_ token: Token) {
        switch token.kind {
        case .plus: self = .plus
        case .minus: self = .minus
        case .asterisk: self = .multiply
        case .forwardSlash: self = .divide
        case .doubleEqual: self = .equal
        case .notEqual: self = .notEqual
        case .lt: self = .lt
        case .ltOrEq: self = .ltOrEq
        case .gt: self = .gt
        case .gtOrEq: self = .gtOrEq
        default: return nil
        }
    }
    
    var precedence: Precedence {
        return rawValue + 1
    }
    
    var description: String {
        switch self {
        case .notEqual: return "!="
        case .equal: return "=="
        case .lt: return "<"
        case .ltOrEq: return "<="
        case .gt: return ">"
        case .gtOrEq: return ">="
        case .plus: return "+"
        case .minus: return "-"
        case .divide: return "/"
        case .multiply: return "*"
        }
    }
}

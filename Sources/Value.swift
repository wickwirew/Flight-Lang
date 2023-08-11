//
//  Value.swift
//  
//
//  Created by wes on 8/12/23.
//

enum Value {
    case builtin(BuiltinFunction)
    case fn(FunctionStmt)
    case int(Int)
    case float(Double)
    case string(String)
    case bool(Bool)
    indirect case array([Value])
    case void
    
    var description: String {
        switch self {
        case .builtin(let f): return f.ident
        case .fn(let f): return f.ident
        case .int(let int): return int.description
        case .float(let double): return double.description
        case .string(let string): return string
        case .bool(let bool): return bool.description
        case .array(let values): return "[\(values.map(\.description).joined(separator: ", "))]"
        case .void: return "void"
        }
    }
}

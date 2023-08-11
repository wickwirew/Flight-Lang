//
//  BuiltinFunction.swift
//  
//
//  Created by wes on 8/12/23.
//

protocol BuiltinFunction {
    var ident: Ident { get }
    var type: Type { get }
    func execute(args: [Value]) throws -> Value
}

var allBuiltinFns: [BuiltinFunction] {
    return [
        PrintFunction(),
        ToStringFunction(),
        RandomInt(),
        RandomFloat(),
        IToF(),
        FToI(),
        IntArray(),
        UnicodeToStringFunction(),
        LenFunction(),
    ]
}
 
struct PrintFunction: BuiltinFunction {
    var ident: Ident {
        return "print"
    }
    
    var type: Type {
        return .fn(nil, .void)
    }
    
    func execute(args: [Value]) throws -> Value {
        print(args.map(\.description).joined())
        return .void
    }
}

struct ToStringFunction: BuiltinFunction {
    var ident: Ident {
        return "to_string"
    }
    
    var type: Type {
        return .fn(nil, .string)
    }
    
    func execute(args: [Value]) throws -> Value {
        return .string(args.map(\.description).joined())
    }
}

struct RandomInt: BuiltinFunction {
    var ident: Ident {
        return "random_int"
    }
    
    var type: Type {
        return .fn([.int, .int], .int)
    }
    
    func execute(args: [Value]) throws -> Value {
        guard case let .int(l) = args[0],
                case let .int(u) = args[1] else { fatalError() }
        return .int(.random(in: l..<u))
    }
}

struct RandomFloat: BuiltinFunction {
    var ident: Ident {
        return "random_float"
    }
    
    var type: Type {
        return .fn([.float, .float], .float)
    }
    
    func execute(args: [Value]) throws -> Value {
        guard case let .float(l) = args[0],
                case let .float(u) = args[1] else { fatalError() }
        return .float(.random(in: l..<u))
    }
}

struct FToI: BuiltinFunction {
    var ident: Ident {
        return "ftoi"
    }
    
    var type: Type {
        return .fn([.float], .int)
    }
    
    func execute(args: [Value]) throws -> Value {
        guard case let .float(v) = args[0] else { fatalError() }
        return .int(Int(v))
    }
}

struct IToF: BuiltinFunction {
    var ident: Ident {
        return "itof"
    }
    
    var type: Type {
        return .fn([.int], .float)
    }
    
    func execute(args: [Value]) throws -> Value {
        guard case let .int(v) = args[0] else { fatalError() }
        return .float(Double(v))
    }
}

struct IntArray: BuiltinFunction {
    var ident: Ident {
        return "int_array"
    }
    
    var type: Type {
        return .fn([.int, .int], .array(.int))
    }
    
    func execute(args: [Value]) throws -> Value {
        guard case let .int(v) = args[0],
              case let .int(l) = args[1] else { fatalError() }
        return .array(Array<Value>(repeating: .int(v), count: l))
    }
}


struct UnicodeToStringFunction: BuiltinFunction {
    var ident: Ident {
        return "unicode_to_string"
    }
    
    var type: Type {
        return .fn([.int], .string)
    }
    
    func execute(args: [Value]) throws -> Value {
        guard case let .int(v) = args[0] else { fatalError() }
        return .string(Character(UnicodeScalar(v)!).description)
    }
}

struct LenFunction: BuiltinFunction {
    var ident: Ident {
        return "len"
    }
    
    var type: Type {
        return .fn(nil, .int)
    }
    
    func execute(args: [Value]) throws -> Value {
        switch args[0] {
        case .array(let arr): return .int(arr.count)
        case .string(let str): return .int(str.count)
        default: return .int(0)
        }
    }
}

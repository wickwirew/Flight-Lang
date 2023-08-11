//
//  Type.swift
//  
//
//  Created by wes on 8/12/23.
//

enum Type: Equatable {
    case int
    case float
    case string
    case bool
    case void
    indirect case array(Type)
    indirect case fn([Type]?, Type)
    
    var isNumeric: Bool {
        return self == .int || self == .float
    }
}

//
//  FlightError.swift
//  
//
//  Created by wes on 8/12/23.
//

enum FlightError: Error, CustomStringConvertible {
    case unexpectedToken(String)
    case notAType(Ident)
    case expecetedExpr
    case notAnOperator(Token)
    case notAllowedAtTopLevel(Stmt)
    case noMainFunction
    case invalidOperator(Operator)
    case cannotExecute(Ident)
    case doesNotExist(Ident)
    case incorrectNumberOfArgs
    case incorrectType(expected: Type, got: Type)
    case cannotReturnHere
    case numericValuesOnly
    case alreadyInScope(Ident)
    case cannotIndexInto(Type)
    case notAllCodePathsReturnAValue
    
    var description: String {
        switch self {
        case .unexpectedToken(let tok):
            return "Unexpected Token '\(tok)'"
        case .notAType(let ident):
            return "No such type '\(ident)'"
        case .expecetedExpr:
            return "Expeceted expression"
        case .notAnOperator(let tok):
            return "'\(tok)' is not an operator"
        case .notAllowedAtTopLevel:
            return "Not allowed at top level"
        case .noMainFunction:
            return "No main function"
        case .invalidOperator(let op):
            return "Invalid operator '\(op)'"
        case .cannotExecute(let ident):
            return "Cannot call non function type '\(ident)'"
        case .doesNotExist(let ident):
            return "'\(ident)' does not exist"
        case .incorrectNumberOfArgs:
            return "Incorrect number of arguments"
        case .incorrectType(let expected, let got):
            return "Incorrect type; Expected '\(expected)' but got '\(got)'"
        case .cannotReturnHere:
            return "Cannot 'return' here"
        case .numericValuesOnly:
            return "Numeric values only"
        case .alreadyInScope(let ident):
            return "'\(ident)' is already in scope"
        case .cannotIndexInto(let t):
            return "Cannot index into type '\(t)'"
        case .notAllCodePathsReturnAValue:
            return "Not all codepaths return a value"
        }
    }
}

//
//  Token.swift
//  
//
//  Created by wes on 8/12/23.
//

struct SourceLocation {
    let range: Range<String.Index>
    let file: String
    
    func spanning(_ range: Range<String.Index>) -> SourceLocation {
        return SourceLocation(
            range: self.range.lowerBound..<range.upperBound,
            file: file
        )
    }
    
    func spanning(_ location: SourceLocation) -> SourceLocation {
        return spanning(location.range)
    }
}

struct Token {
    let kind: Kind
    let leadingTrivia: Trivia
    let trailingTrivia: Trivia
    let location: SourceLocation
    
    init(
        kind: Kind,
        leadingTrivia: Trivia,
        trailingTrivia: Trivia,
        location: SourceLocation
    ) {
        self.kind = kind
        self.leadingTrivia = leadingTrivia
        self.trailingTrivia = trailingTrivia
        self.location = location
    }
    
    enum Kind: Equatable, CustomStringConvertible {
        case float(Double)
        case int(Int)
        case bool(Bool)
        case ident(String)
        case string(String)
        case fn
        case `let`
        case `return`
        case `if`
        case `else`
        case `while`
        case openParen
        case closeParen
        case comma
        case colon
        case openCurly
        case closeCurly
        case openSquare
        case closeSquare
        case plus
        case minus
        case asterisk
        case forwardSlash
        case equals
        case doubleEqual
        case notEqual
        case lt
        case ltOrEq
        case gt
        case gtOrEq
        case bang
        case eof
        
        init(word: String) {
            switch word {
            case "fn": self = .fn
            case "return": self = .return
            case "let": self = .let
            case "if": self = .`if`
            case "else": self = .`else`
            case "true": self = .bool(true)
            case "false": self = .bool(false)
            case "while": self = .while
            default: self = .ident(word)
            }
        }
        
        var description: String {
            switch self {
            case .float(let double):
                return double.description
            case .int(let int):
                return int.description
            case .ident(let string):
                return string
            case .string(let string):
                return string
            case .bool(let bool):
                return bool.description
            case .fn:
                return "fn"
            case .let:
                return "let"
            case .`return`:
                return "return"
            case .if:
                return "if"
            case .else:
                return "else"
            case .while:
                return "while"
            case .openParen:
                return "("
            case .closeParen:
                return ")"
            case .comma:
                return ","
            case .colon:
                return ":"
            case .openCurly:
                return "{"
            case .closeCurly:
                return "}"
            case .openSquare:
                return "["
            case .closeSquare:
                return "]"
            case .plus:
                return "+"
            case .minus:
                return "-"
            case .asterisk:
                return "*"
            case .forwardSlash:
                return "/"
            case .equals:
                return "="
            case .doubleEqual:
                return "=="
            case .notEqual:
                return "!="
            case .bang:
                return "!"
            case .lt:
                return "<"
            case .ltOrEq:
                return "<="
            case .gt:
                return ">"
            case .gtOrEq:
                return ">="
            case .eof:
                return "<eof>"
            }
        }
    }
    
    enum Trivia {
        case newline
        case whitespace
        case none
    }
}

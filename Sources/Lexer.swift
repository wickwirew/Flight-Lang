//
//  Lexer.swift
//  
//
//  Created by wes on 8/11/23.
//

class Lexer {
    let fileName: String
    let source: String
    let errors: ErrorHandler
    var current: String.Index
    var peek: String.Index
    
    init(fileName: String, source: String, errors: ErrorHandler) {
        self.fileName = fileName
        self.source = source
        self.errors = errors
        self.current = source.startIndex
        self.peek = source.index(after: current)
    }
    
    var currentChar: Character {
        return source[current]
    }
    
    var peekChar: Character? {
        return peek >= source.endIndex ? nil : source[peek]
    }
    
    var hasMore: Bool {
        return current < source.endIndex
    }
    
    func next() -> Token {
        skipWhitespace()
        
        guard current < source.endIndex else {
            return Token(
                kind: .eof,
                leadingTrivia: .none,
                trailingTrivia: .none,
                location: SourceLocation(
                    range: current..<peek,
                    file: fileName
                )
            )
        }
        
        let char = source[current]
        
        if char.isNumber {
            return number()
        } else if char.isLetter || char == "_" {
            return identOrKeyword()
        }
        
        switch char {
        case "(":
            return single(kind: .openParen)
        case ")":
            return single(kind: .closeParen)
        case "{":
            return single(kind: .openCurly)
        case "}":
            return single(kind: .closeCurly)
        case "[":
            return single(kind: .openSquare)
        case "]":
            return single(kind: .closeSquare)
        case ",":
            return single(kind: .comma)
        case ":":
            return single(kind: .colon)
        case "+":
            return single(kind: .plus)
        case "-":
            return single(kind: .minus)
        case "*":
            return single(kind: .asterisk)
        case "/":
            return single(kind: .forwardSlash)
        case "=":
            let index = current
            consume()
            if currentChar == "=" {
                consume()
                return makeToken(kind: .doubleEqual, range: index..<current)
            } else {
                return makeToken(kind: .equals, range: index..<current)
            }
        case "!":
            let index = current
            consume()
            if currentChar == "=" {
                consume()
                return makeToken(kind: .notEqual, range: index..<current)
            } else {
                return makeToken(kind: .bang, range: index..<current)
            }
        case "<":
            let index = current
            consume()
            if currentChar == "=" {
                consume()
                return makeToken(kind: .ltOrEq, range: index..<current)
            } else {
                return makeToken(kind: .lt, range: index..<current)
            }
        case ">":
            let index = current
            consume()
            if currentChar == "=" {
                consume()
                return makeToken(kind: .gtOrEq, range: index..<current)
            } else {
                return makeToken(kind: .gt, range: index..<current)
            }
        case "\"":
            return string()
        default:
            errors.add(
                .unexpectedToken(char.description),
                at: SourceLocation(range: current..<peek, file: fileName)
            )
            consume()
            return next()
        }
    }
    
    private func single(kind: Token.Kind) -> Token {
        let index = current
        consume()
        return makeToken(kind: kind, range: index..<current)
    }
    
    private func makeToken(kind: Token.Kind, range: Range<String.Index>) -> Token {
        let leading: Token.Trivia = range.lowerBound > source.startIndex
            ? trivia(at: source.index(before: range.lowerBound))
            : .none
        
        let trailing: Token.Trivia = range.upperBound < source.endIndex
            ? trivia(at: range.upperBound)
            : .none
        
        return Token(
            kind: kind,
            leadingTrivia: leading,
            trailingTrivia: trailing,
            location: SourceLocation(
                range: range,
                file: fileName
            )
        )
    }
    
    private func trivia(at index: String.Index) -> Token.Trivia {
        switch source[index] {
        case "\n": return .newline
        case " ", "\t": return .whitespace
        default: return .none
        }
    }
    
    private func number() -> Token {
        var char = source[current]
        var foundDot = false
        let start = current
        
        while char.isNumber || char == "." {
            if char == "." {
                if peekChar?.isNumber == true {
                    foundDot = true
                    consume()
                    consume()
                } else if foundDot {
                    break
                }
            } else {
                consume()
            }
            char = currentChar
        }
        
        let range = start..<current
        let str = source[range]
        
        if foundDot {
            return makeToken(kind: .float(Double(str) ?? 0), range: range)
        } else {
            return makeToken(kind: .int(Int(str) ?? 0), range: range)
        }
    }
    
    private func identOrKeyword() -> Token {
        let start = current
        consume()
        
        var char = currentChar
        while char.isLetter || char == "_" || char.isNumber {
            consume()
            char = currentChar
        }
        
        let range = start..<current
        
        return makeToken(kind: Token.Kind(word: String(source[range])), range: range)
    }
    
    private func string() -> Token {
        consume()
        let start = current
        while hasMore && currentChar != "\"" {
            consume()
        }
        let range = start..<current
        let string = String(source[start..<current])
        consume()
        return makeToken(kind: .string(string), range: range)
    }
    
    private func consume() {
        current = peek
        
        if peek < source.endIndex {
            peek = source.index(after: peek)
        }
    }
    
    private func skipWhitespace() {
        while hasMore && source[current].isWhitespace {
            consume()
        }
    }
}

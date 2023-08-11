// The Swift Programming Language
// https://docs.swift.org/swift-book

enum ParsingError: Error {
    case unexpectedToken(String)
    case notAStmt(Token)
    case notAType(Ident)
    case expecetedExpr
    case notAnOperator(Token)
    case notAllowedAtTopLevel(Stmt)
    case noMainFunction
    case invalidOperator(Operator)
}

enum Token: Equatable, CustomStringConvertible {
    case float(Double)
    case int(Int)
    case ident(String)
    case string(String)
    case fn
    case `return`
    case openParen
    case closeParen
    case comma
    case colon
    case openCurly
    case closeCurly
    case plus
    case minus
    case asterisk
    case forwardSlash
    case eof
    
    init(word: String) {
        switch word {
        case "fn": self = .fn
        case "return": self = .`return`
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
        case .fn:
            return "fn"
        case .`return`:
            return "return"
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
        case .plus:
            return "+"
        case .minus:
            return "-"
        case .asterisk:
            return "*"
        case .forwardSlash:
            return "/"
        case .eof:
            return "<eof>"
        }
    }
}

class Lexer {
    let source: String
    var current: String.Index
    var peek: String.Index
    
    init(source: String) {
        self.source = source
        self.current = source.startIndex
        self.peek = source.index(after: current)
    }
    
    var currentChar: Character {
        return source[current]
    }
    
    var peekChar: Character? {
        return peek >= source.endIndex ? nil : source[peek]
    }
    
    func next() throws -> Token {
        guard current < source.endIndex else { return .eof }
        
        skipWhitespace()
        
        let char = source[current]
        
        if char.isNumber {
            return number()
        } else if char.isLetter || char == "_" {
            return identOrKeyword()
        }
        
        switch char {
        case "(":
            consume()
            return .openParen
        case ")":
            consume()
            return .closeParen
        case "{":
            consume()
            return .openCurly
        case "}":
            consume()
            return .closeCurly
        case ",":
            consume()
            return .comma
        case ":":
            consume()
            return .colon
        case "+":
            consume()
            return .plus
        case "-":
            consume()
            return .minus
        case "*":
            consume()
            return .asterisk
        case "/":
            consume()
            return .forwardSlash
        default: throw ParsingError.unexpectedToken(char.description)
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
        
        if foundDot {
            return .float(Double(source[start..<current]) ?? 0)
        } else {
            return .int(Int(source[start..<current]) ?? 0)
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
        
        return Token(word: String(source[start..<current]))
    }
    
    private func consume() {
        current = peek
        
        if peek < source.endIndex {
            peek = source.index(after: peek)
        }
    }
    
    private func skipWhitespace() {
        while source[current].isWhitespace {
            consume()
        }
    }
}

enum Type {
    case int
    case float
    case string
    case void
}

protocol Stmt {}
protocol Expr {}
typealias Ident = String

struct Function: Stmt {
    let ident: Ident
    let params: [(Ident, Type)]
    let returnType: Type
    let body: [Stmt]
}

struct ReturnStmt: Stmt {
    let result: Expr
}

struct ExprStmt: Stmt {
    let expr: Expr
}

struct IntLit: Expr {
    let int: Int
}

struct FloatLit: Expr {
    let float: Double
}

struct StringLit: Expr {
    let string: String
}

struct IdentExpr: Expr {
    let ident: Ident
}

struct InfixExpr: Expr {
    let lhs: Expr
    let `operator`: Operator
    let rhs: Expr
}

typealias Precedence = Int

enum Operator {
    case plus
    case minus
    case multiply
    case divide
    
    init?(_ token: Token) {
        switch token {
        case .plus: self = .plus
        case .minus: self = .minus
        case .asterisk: self = .multiply
        case .forwardSlash: self = .divide
        default: return nil
        }
    }
    
    var precedence: Precedence {
        switch self {
        case .plus: return 1
        case .minus: return 2
        case .divide: return 3
        case .multiply: return 4
        }
    }
}

class Parser {
    let lexer: Lexer
    var current: Token
    var peek: Token
    
    init(lexer: Lexer) throws {
        self.lexer = lexer
        self.current = try lexer.next()
        self.peek = try lexer.next()
    }
    
    func parse() throws -> [Stmt] {
        var stmts: [Stmt] = []
        
        while current != .eof {
            guard let stmt = try parseStmt() else { continue }
            stmts.append(stmt)
        }
        
        return stmts
    }
    
    private func consume() throws {
        current = peek
        peek = try lexer.next()
    }
    
    private func consume(_ token: Token) throws {
        guard current == token else { throw ParsingError.unexpectedToken(current.description) }
        try consume()
    }
    
    private func consumeIdent() throws {
        guard case .ident = current else { throw ParsingError.unexpectedToken(current.description) }
        try consume()
    }
    
    private func parseIdent() throws -> Ident {
        guard case .ident(let value) = current else {
            throw ParsingError.unexpectedToken(current.description)
        }
        
        try consume()
        return value
    }
    
    private func parseType() throws -> Type {
        let name = try parseIdent()
        
        switch name {
        case "int": return .int
        case "float": return .float
        case "string": return .string
        case "void": return .void
        default: throw ParsingError.notAType(name)
        }
    }
    
    private func parseStmt() throws -> Stmt? {
        switch current {
        case .fn:
            return try parseFunction()
        case .return:
            return try parseReturn()
        case .eof:
            return nil
        default:
            return try ExprStmt(expr: parseExpr())
        }
    }
    
    private func parseFunction() throws -> Function {
        try consume(.fn)
        let ident = try parseIdent()
        try consume(.openParen)
        
        var params: [(Ident, Type)] = []
        
        if current == .closeParen {
            try consume()
        } else {
            var isFirst = true
            
            repeat {
                if isFirst {
                    isFirst = false
                } else {
                    try consume(.comma)
                }
                
                let name = try parseIdent()
                try consume(.colon)
                let type = try parseType()
                params.append((name, type))
            } while current == .comma
            
            try consume(.closeParen)
        }
        
        let returnType: Type
        if current == .openCurly {
            returnType = .void
        } else {
            returnType = try parseType()
        }
        
        return Function(
            ident: ident,
            params: params,
            returnType: returnType,
            body: try parseBody()
        )
    }
    
    private func parseBody() throws -> [Stmt] {
        try consume(.openCurly)
        var stmts: [Stmt] = []
        
        while current != .eof && current != .closeCurly {
            guard let stmt = try parseStmt() else { continue }
            stmts.append(stmt)
        }
        
        try consume(.closeCurly)
        return stmts
    }
    
    private func parseReturn() throws -> ReturnStmt {
        try consume(.return)
        return ReturnStmt(result: try parseExpr())
    }
    
    private func parseExpr(precedence: Precedence = 0) throws -> Expr {
        var expr = try parseExprLhs()
        
        while true {
            let currentPrecedence: Precedence
            switch current {
            case .openParen:
                currentPrecedence = 7
            default:
                currentPrecedence = 0
            }
            
            if precedence > currentPrecedence {
                break
            } else {
                guard let op = Operator(current) else {
                    return expr
                }
                
                try consume()
                
                expr = try parseInfix(lhs: expr, operator: op)
            }
        }
        
        return expr
    }
    
    private func parseInfix(lhs: Expr, operator: Operator) throws -> Expr {
        switch current {
        case .openParen:
            fatalError("call")
        default:
            let rhs = try parseExpr(precedence: `operator`.precedence)
            return InfixExpr(lhs: lhs, operator: `operator`, rhs: rhs)
        }
    }
    
    private func parseExprLhs() throws -> Expr {
        switch current {
        case .float(let value):
            try consume()
            return FloatLit(float: value)
        case .int(let value):
            try consume()
            return IntLit(int: value)
        case .string(let value):
            try consume()
            return StringLit(string: value)
        case .ident(let value):
            try consume()
            return IdentExpr(ident: value)
        default:
            throw ParsingError.expecetedExpr
        }
    }
}

class TypeChecker {
    let stmts: [Stmt]
    
    init(stmts: [Stmt]) {
        self.stmts = stmts
    }
    
    func check() throws -> [Function] {
        var functions: [Function] = []
        
        for stmt in stmts {
            switch stmt {
            case let stmt as Function:
                try check(function: stmt)
                functions.append(stmt)
            default:
                throw ParsingError.notAllowedAtTopLevel(stmt)
            }
        }
        
        return functions
    }
    
    private func check(function: Function) throws {
        
    }
}

enum BuiltinFunction {
    case print
    
    var ident: Ident {
        switch self {
        case .print: return "print"
        }
    }
    
    func execute(args: [Expr]) {
        switch self {
        case .print:
            Swift.print("PRinttttt")
        }
    }
}

class Interpreter {
    let functions: [Ident: Function]
    var scope: [Ident: ExprResult] = [:]

    init(functions: [Function]) {
        self.functions = functions.reduce(into: [:], { $0[$1.ident] = $1 })
    }

    func execute() throws {
        guard let main = functions["main"] else {
            throw ParsingError.noMainFunction
        }
        
        try execute(function: main)
    }
    
    private func execute(function: Function) throws {
        for stmt in function.body {
            try execute(stmt: stmt)
        }
    }
    
    private func execute(stmt: Stmt) throws{
        switch stmt {
        case let fn as Function:
            try execute(function: fn)
        case let expr as ExprStmt:
            print(try execute(expr: expr.expr))
        default:
            fatalError()
        }
    }
    
    private func execute(expr: Expr) throws -> ExprResult{
        switch expr {
        case let int as IntLit: return .int(int.int)
        case let float as FloatLit: return .float(float.float)
        case let string as StringLit: return .string(string.string)
        case let `infix` as InfixExpr:
            let lhs = try execute(expr: `infix`.lhs)
            let rhs = try execute(expr: `infix`.rhs)
            // TODO: other operators
            switch (lhs, rhs) {
            case let (.int(l), .int(r)):
                return .int(l + r)
            case let (.float(l), .float(r)):
                return .float(l + r)
            case let (.string(l), .string(r)):
                return .string(l + r)
            case let (.float(l), .int(r)):
                return .float(l + Double(r))
            case let (.int(l), .float(r)):
                return .float(Double(l) + r)
            default:
                throw ParsingError.invalidOperator(infix.operator)
            }
        default: fatalError()
        }
    }
}

enum ExprResult {
    case int(Int)
    case float(Double)
    case string(String)
}


let source = """
fn main() {
    1 + 2
}
"""



let lexer = Lexer(source: source)
let parser = try Parser(lexer: lexer)
let stmts = try parser.parse()
let typeChecker = TypeChecker(stmts: stmts)
let functions = try typeChecker.check()
let interpreter = Interpreter(functions: functions)

try interpreter.execute()

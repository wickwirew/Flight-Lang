//
//  Parser.swift
//  
//
//  Created by wes on 8/11/23.
//

class Parser {
    let lexer: Lexer
    let errors: ErrorHandler
    var current: Token
    var peek: Token
    
    init(lexer: Lexer, errors: ErrorHandler) {
        self.lexer = lexer
        self.errors = errors
        self.current = lexer.next()
        self.peek = lexer.next()
    }
    
    func parse() -> [Stmt] {
        var stmts: [Stmt] = []
        
        while current.kind != .eof {
            do {
                guard let stmt = try parseStmt() else { continue }
                stmts.append(stmt)
            } catch {
                recover()
            }
        }
        
        return stmts
    }
    
    private func recover() {
        while current.kind != .eof && current.leadingTrivia != .newline {
            consume()
        }
    }
    
    private func consume() {
        current = peek
        peek = lexer.next()
    }
    
    private func consume(_ token: Token.Kind) throws {
        guard current.kind == token else {
            throw errors.add(.unexpectedToken(current.kind.description), for: current)
        }
        
        consume()
    }
    
    private func consumeIdent() throws {
        guard case .ident = current.kind else {
            throw errors.add(.unexpectedToken(current.kind.description), for: current)
        }
        
        consume()
    }
    
    private func parseIdent() throws -> Ident {
        guard case .ident(let value) = current.kind else {
            throw errors.add(.unexpectedToken(current.kind.description), for: current)
        }
        
        consume()
        return value
    }
    
    private func parseType() throws -> Type {
        if current.kind == .openSquare {
            consume()
            let t = try parseType()
            try consume(.closeSquare)
            return .array(t)
        } else {
            let location = current.location
            let name = try parseIdent()
            
            switch name {
            case "int": return .int
            case "float": return .float
            case "string": return .string
            case "void": return .void
            case "bool": return .bool
            default: throw errors.add(.notAType(name), at: location)
            }
        }
    }
    
    private func parseStmt() throws -> Stmt? {
        switch current.kind {
        case .fn:
            return try parseFunction()
        case .return:
            return try parseReturn()
        case .let:
            return try parseLetStmt()
        case .if:
            return try parseIfStmt()
        case .while:
            return try parseWhile()
        case .eof:
            return nil
        default:
            return try ExprStmt(expr: parseExpr())
        }
    }
    
    private func parseFunction() throws -> FunctionStmt {
        let start = current.location
        try consume(.fn)
        let ident = try parseIdent()
        try consume(.openParen)
        
        var params: [(Ident, Type)] = []
        
        if current.kind == .closeParen {
            consume()
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
            } while current.kind == .comma
            
            try consume(.closeParen)
        }
        
        let returnType: Type
        if current.kind == .openCurly {
            returnType = .void
        } else {
            returnType = try parseType()
        }
        
        let end = current.location
        
        return FunctionStmt(
            ident: ident,
            params: params,
            returnType: returnType,
            location: start.spanning(end),
            body: try parseBody()
        )
    }
    
    private func parseBody() throws -> BodyStmt {
        let start = current.location
        try consume(.openCurly)
        var stmts: [Stmt] = []
        
        while current.kind != .eof && current.kind != .closeCurly {
            do {
                guard let stmt = try parseStmt() else { continue }
                stmts.append(stmt)
            } catch {
                recover()
            }
        }
        
        try consume(.closeCurly)
        return BodyStmt(stmts: stmts, location: start.spanning(current.location))
    }
    
    private func parseReturn() throws -> ReturnStmt {
        let location = current.location
        try consume(.return)
        return ReturnStmt(result: try parseExpr(), location: location)
    }
    
    private func parseExpr(precedence: Precedence = 0) throws -> Expr {
        var expr = try parseExprLhs()
        
        while true {
            if current.kind == .equals  {
                consume()
                let value = try parseExpr()
                expr = AssignExpr(
                    receiver: expr,
                    value: value,
                    location: expr.location.spanning(value.location)
                )
            } else if current.kind == .openSquare {
                consume()
                let index = try parseExpr()
                try consume(.closeSquare)
                expr = SubScriptExpr(value: expr, index: index)
            } else if let op = Operator(current) {
                guard op.precedence > precedence else { break }
                consume()
                expr = try parseInfix(lhs: expr, operator: op)
            } else if current.kind == .openParen, let ident = expr as? IdentExpr {
                expr = try parseCall(function: ident.ident, identLocation: ident.location)
            } else {
                break
            }
        }
        
        return expr
    }
    
    private func parseInfix(lhs: Expr, operator: Operator) throws -> Expr {
        let rhs = try parseExpr(precedence: `operator`.precedence)
        return InfixExpr(lhs: lhs, operator: `operator`, rhs: rhs)
    }
    
    private func parseExprLhs() throws -> Expr {
        let location = current.location
        switch current.kind {
        case .float(let value):
            consume()
            return FloatLit(float: value, location: location)
        case .int(let value):
            consume()
            return IntLit(int: value, location: location)
        case .string(let value):
            consume()
            return StringLit(string: value, location: location)
        case .ident(let value):
            consume()
            return IdentExpr(ident: value, location: location)
        case .bool(let value):
            consume()
            return BoolLit(bool: value, location: location)
        case .openSquare:
            consume()
            var values: [Expr] = []
            
            while current.kind != .closeSquare && current.kind != .eof {
                try values.append(parseExpr())
                
                if current.kind == .comma {
                    consume()
                }
            }
            
            try consume(.closeSquare)
            
            return ArrayLit(values: values, location: location)
        default:
            throw errors.add(.expecetedExpr, for: current)
        }
    }
    
    private func parseCall(function: Ident, identLocation: SourceLocation) throws -> CallExpr {
        try consume(.openParen)
        
        var args: [Expr] = []
        if current.kind != .closeParen {
            var hasMore = false
            repeat {
                try args.append(parseExpr())
                
                if current.kind == .comma {
                    consume()
                    hasMore = true
                } else {
                    hasMore = false
                }
            } while hasMore
        }
        
        let end = current.location
        try consume(.closeParen)
        
        return CallExpr(
            function: function,
            args: args,
            location: identLocation.spanning(end)
        )
    }
    
    private func parseLetStmt() throws -> LetStmt {
        let letLocation = current.location
        try consume(.let)
        let name = try parseIdent()
        try consume(.equals)
        let value = try parseExpr()
        return LetStmt(ident: name, expr: value, location: letLocation.spanning(current.location))
    }
    
    private func parseIfStmt() throws -> IfStmt {
        let start = current.location
        try consume(.if)
        let condition = try parseExpr()
        let location = start.spanning(current.location)
        let body = try parseBody()
        
        if current.kind == .else {
            consume()
            
            if current.kind == .if {
                return try IfStmt(condition: condition, body: body, else: .elseIf(parseIfStmt()), location: location)
            } else {
                return try IfStmt(condition: condition, body: body, else: .else(parseBody()), location: location)
            }
        } else {
            return IfStmt(condition: condition, body: body, else: nil, location: location)
        }
    }
    
    private func parseWhile() throws -> WhileStmt {
        try consume(.while)
        let condition = try parseExpr()
        let body = try parseBody()
        return WhileStmt(condition: condition, body: body)
    }
}

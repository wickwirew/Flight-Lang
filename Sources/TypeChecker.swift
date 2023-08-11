//
//  TypeChecker.swift
//  
//
//  Created by wes on 8/11/23.
//

class TypeChecker {
    let stmts: [Stmt]
    let errors: ErrorHandler
    var scope: Scope<Type>
    
    init(stmts: [Stmt], errors: ErrorHandler) {
        self.stmts = stmts
        self.errors = errors
        self.scope = Scope<Type>(
            values: allBuiltinFns
                .reduce(into: [:]){ $0[$1.ident] = $1.type }
        )
        
        // TODO: Got to be a cleaner way to do this
        for stmt in stmts  {
            guard let f = stmt as? FunctionStmt else { continue }

            scope.insert(
                ident: f.ident,
                value: .fn(f.params.map(\.1), f.returnType)
            )
        }
    }
    
    func check() throws {
        for stmt in stmts {
            try stmt.accept(visitor: self)
        }
    }
}

extension TypeChecker: StmtVisitor {
    func visit(function: FunctionStmt) throws {
        scope.insert(
            ident: function.ident,
            value: .fn(function.params.map(\.1), function.returnType)
        )
        
        scope = scope.pushing(context: .fn(returnType: function.returnType))
        defer { scope = scope.popping() }
        
        for param in function.params {
            scope.insert(ident: param.0, value: param.1)
        }
        
        try function.body.accept(visitor: self)
        
        let flowAnalysis = FlowAnalysis(errors: errors)
        try flowAnalysis.validatePaths(function: function)
    }
    
    func visit(return: ReturnStmt) throws {
        // Make sure matches current scope
        let t = try `return`.result.accept(visitor: self)
        
        guard case let .fn(returnType) = scope.context else {
            errors.add(.cannotReturnHere, at: `return`.location)
            return
        }
        
        if t != returnType {
            errors.add(.incorrectType(expected: returnType, got: t), at: `return`.location)
        }
    }
    
    func visit(`let`: LetStmt) throws {
        if scope.get(ident: `let`.ident, checkParent: false) != nil {
            errors.add(.alreadyInScope(`let`.ident), at: `let`.location)
        }
        
        try scope.insert(ident: `let`.ident, value: `let`.expr.accept(visitor: self))
    }
    
    func visit(expr: ExprStmt) throws {
        _ = try expr.expr.accept(visitor: self)
    }
    
    func visit(body: BodyStmt) throws {
        for stmt in body.stmts {
            try stmt.accept(visitor: self)
        }
    }
    
    func visit(if: IfStmt) throws {
        let condition = try `if`.condition.accept(visitor: self)
        
        guard condition == .bool else {
            errors.add(.incorrectType(expected: .bool, got: condition), at: `if`.location)
            return
        }
        
        switch `if`.else {
        case .else(let body):
            try body.accept(visitor: self)
        case .elseIf(let elseIf):
            try elseIf.accept(visitor: self)
        case nil:
            break
        }
    }
    
    func visit(while: WhileStmt) throws {
        let condition = try `while`.condition.accept(visitor: self)
        
        if condition != .bool {
            errors.add(.incorrectType(expected: .bool, got: condition), at: `while`.location)
        }
        
        try `while`.body.accept(visitor: self)
    }
}

extension TypeChecker: ExprVisitor {
    func visit(int: IntLit) throws -> Type {
        return .int
    }
    
    func visit(float: FloatLit) throws -> Type {
        return .float
    }
    
    func visit(string: StringLit) throws -> Type {
        return .string
    }
    
    func visit(bool: BoolLit) throws -> Type {
        return .bool
    }
    
    func visit(subscript: SubScriptExpr) throws -> Type {
        let value = try `subscript`.value.accept(visitor: self)
        
        switch value {
        case .array(let ofType):
            return ofType
        case .string:
            return .string
        default:
            errors.add(.cannotIndexInto(value), at: `subscript`.location)
            return value
        }
    }
    
    func visit(array: ArrayLit) throws -> Type {
        var type: Type?
        
        for expr in array.values {
            let eType = try expr.accept(visitor: self)
            
            if let type {
                if type != eType {
                    errors.add(.incorrectType(expected: type, got: eType), at: expr.location)
                }
            } else {
                type = eType
            }
        }
        
        return .array(type ?? .void)
    }
    
    func visit(ident: IdentExpr) throws -> Type {
        guard let type = scope.get(ident: ident.ident) else {
            errors.add(.doesNotExist(ident.ident), at: ident.location)
            return .void
        }
        
        return type
    }
    
    func visit(call: CallExpr) throws -> Type {
        guard let type = scope.get(ident: call.function) else {
            errors.add(.doesNotExist(call.function), at: call.location)
            return .void
        }
        
        guard case let .fn(args, ret) = type else {
            errors.add(.cannotExecute(call.function), at: call.location)
            return .void
        }
        
        if let args {
            guard args.count == call.args.count else {
                errors.add(.incorrectNumberOfArgs, at: call.location)
                return ret
            }
            
            for i in 0..<args.count {
                let t = try call.args[i].accept(visitor: self)
                
                if args[i] != t {
                    errors.add(.incorrectType(expected: args[i], got: t), at: call.location)
                    return ret
                }
            }
        } else {
            for arg in call.args {
                _ = try arg.accept(visitor: self)
            }
        }
        
        return ret
    }
    
    func visit(infix: InfixExpr) throws -> Type {
        let lhs = try infix.lhs.accept(visitor: self)
        let rhs = try infix.rhs.accept(visitor: self)
        
        switch infix.operator {
        case .notEqual, .equal:
            return .bool
        case .lt, .ltOrEq, .gt, .gtOrEq:
            validateIsNumeric(lhs, location: infix.lhs.location)
            validateIsNumeric(rhs, location: infix.rhs.location)
            return .bool
        case .minus, .divide, .multiply:
            validateIsNumeric(lhs, location: infix.lhs.location)
            validateIsNumeric(rhs, location: infix.rhs.location)
            return lhs == .float || rhs == .float ? .float : .int
        case .plus:
            if lhs.isNumeric && rhs.isNumeric {
                return lhs == .float || rhs == .float ? .float : .int
            } else if lhs == .string {
                return .string
            } else if rhs == .string {
                return .string
            } else if case .array(let ofType) = lhs, ofType == rhs {
                return .array(ofType)
            } else {
                errors.add(.invalidOperator(infix.operator), at: infix.location)
                return .int
            }
        }
    }
    
    func visit(assign: AssignExpr) throws -> Type {
        let reciever = try assign.receiver.accept(visitor: self)
        let value = try assign.value.accept(visitor: self)
        
        guard reciever == value else {
            errors.add(.incorrectType(expected: reciever, got: value), at: assign.location)
            return .void
        }
        
        return .void
    }
    
    private func validateIsNumeric(_ type: Type, location: SourceLocation) {
        if !type.isNumeric {
            errors.add(.numericValuesOnly, at: location)
        }
    }
}

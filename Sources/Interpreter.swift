//
//  Interpreter.swift
//  
//
//  Created by wes on 8/11/23.
//

class Interpreter {
    var scope: Scope<Value>
    
    struct Return: Error {
        let value: Value
    }

    init(stmts: [Stmt]) throws {
        self.scope = Scope<Value>(
            values: allBuiltinFns
                .reduce(into: [:]){ $0[$1.ident] = .builtin($1) }
        )
        try self.populateGlobal(with: stmts)
    }

    func execute() throws {
        guard let main = scope.get(ident: "main"), case let .fn(function) = main else {
            throw FlightError.noMainFunction
        }
        
        try function.body.accept(visitor: self)
    }
    
    func typeCheckerMissed() -> Never {
        fatalError("Type checker missed something")
    }
    
    private func populateGlobal(with stmts: [Stmt]) throws {
        for stmt in stmts {
            try stmt.accept(visitor: self)
        }
    }
}

extension Interpreter: StmtVisitor {
    func visit(function: FunctionStmt) throws {
        scope.insert(ident: function.ident, value: .fn(function))
    }
    
    func visit(return: ReturnStmt) throws {
        let value = try `return`.result.accept(visitor: self)
        throw Return(value: value)
    }
    
    func visit(`let`: LetStmt) throws {
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
        
        guard case let .bool(value) = condition else {
            typeCheckerMissed()
        }
        
        if value {
            try `if`.body.accept(visitor: self)
        } else {
            switch `if`.else {
            case .else(let body):
                try body.accept(visitor: self)
            case .elseIf(let `if`):
                try `if`.accept(visitor: self)
            case .none:
                break
            }
        }
    }
    
    func visit(while: WhileStmt) throws {
        let condition = try `while`.condition.accept(visitor: self)
        
        guard case var .bool(value) = condition else {
            typeCheckerMissed()
        }
        
        while value {
            try `while`.body.accept(visitor: self)
            
            let condition = try `while`.condition.accept(visitor: self)
            
            guard case let .bool(newValue) = condition else {
                typeCheckerMissed()
            }
            
            value = newValue
        }
    }
}

extension Interpreter: ExprVisitor {
    func visit(int: IntLit) throws -> Value {
        return .int(int.int)
    }
    
    func visit(float: FloatLit) throws -> Value {
        return .float(float.float)
    }
    
    func visit(string: StringLit) throws -> Value {
        return .string(string.string)
    }
    
    func visit(bool: BoolLit) throws -> Value {
        return .bool(bool.bool)
    }
    
    func visit(ident: IdentExpr) throws -> Value {
        guard let value = scope.get(ident: ident.ident) else {
            typeCheckerMissed()
        }
        return value
    }
    
    func visit(array: ArrayLit) throws -> Value {
        return try .array(array.values.map{ try $0.accept(visitor: self) })
    }
    
    func visit(call: CallExpr) throws -> Value {
        guard let value = scope.get(ident: call.function) else {
            typeCheckerMissed()
        }
        
        let args = try call.args.map{ try $0.accept(visitor: self) }
        
        switch value {
        case .builtin(let builtin):
            return try builtin.execute(args: args)
        case .fn(let function):
            scope = scope.pushing()
            defer { scope = scope.popping() }
            
            for (i, arg) in args.enumerated() {
                scope.insert(ident: function.params[i].0, value: arg)
            }
            
            do {
                try function.body.accept(visitor: self)
                return .void
            } catch let error as Return {
                return error.value
            } catch {
                fatalError("\(error)")
            }
        default:
            typeCheckerMissed()
        }
    }
    
    func visit(assign: AssignExpr) throws -> Value {
        let storage = try storage(for: assign.receiver)
        let value = try assign.value.accept(visitor: self)
        storage?.write(value)
        return .void
    }
    
    func visit(subscript: SubScriptExpr) throws -> Value {
        let index = try `subscript`.index.accept(visitor: self)
        
        guard case let .int(i) = index,
              let storage = try storage(for: `subscript`.value) else { typeCheckerMissed() }

        return storage.at(index: i).read()!
    }
    
    func visit(infix: InfixExpr) throws -> Value {
        let lhs = try `infix`.lhs.accept(visitor: self)
        let rhs = try `infix`.rhs.accept(visitor: self)
        
        switch `infix`.operator {
        case .plus:
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
            case let (.string(s), _):
                return .string(s + rhs.description)
            case let (_, .string(s)):
                return .string(lhs.description + s)
            case (.array(var values), let new):
                values.append(new)
                return .array(values)
            default:
                typeCheckerMissed()
            }
        case .minus:
            switch (lhs, rhs) {
            case let (.int(l), .int(r)):
                return .int(l - r)
            case let (.float(l), .float(r)):
                return .float(l - r)
            case let (.float(l), .int(r)):
                return .float(l - Double(r))
            case let (.int(l), .float(r)):
                return .float(Double(l) - r)
            default:
                typeCheckerMissed()
            }
        case .multiply:
            switch (lhs, rhs) {
            case let (.int(l), .int(r)):
                return .int(l * r)
            case let (.float(l), .float(r)):
                return .float(l * r)
            case let (.float(l), .int(r)):
                return .float(l * Double(r))
            case let (.int(l), .float(r)):
                return .float(Double(l) * r)
            default:
                typeCheckerMissed()
            }
        case .divide:
            switch (lhs, rhs) {
            case let (.int(l), .int(r)):
                return .int(l / r)
            case let (.float(l), .float(r)):
                return .float(l / r)
            case let (.float(l), .int(r)):
                return .float(l / Double(r))
            case let (.int(l), .float(r)):
                return .float(Double(l) / r)
            default:
                typeCheckerMissed()
            }
        case .equal:
            switch (lhs, rhs) {
            case let (.int(l), .int(r)):
                return .bool(l == r)
            case let (.float(l), .float(r)):
                return .bool(l == r)
            case let (.string(l), .string(r)):
                return .bool(l == r)
            case let (.float(l), .int(r)):
                return .bool(l == Double(r))
            case let (.int(l), .float(r)):
                return .bool(Double(l) == r)
            case let (.bool(l), .bool(r)):
                return .bool(l == r)
            default:
                typeCheckerMissed()
            }
        case .notEqual:
            switch (lhs, rhs) {
            case let (.int(l), .int(r)):
                return .bool(l != r)
            case let (.float(l), .float(r)):
                return .bool(l != r)
            case let (.string(l), .string(r)):
                return .bool(l != r)
            case let (.float(l), .int(r)):
                return .bool(l != Double(r))
            case let (.int(l), .float(r)):
                return .bool(Double(l) != r)
            case let (.bool(l), .bool(r)):
                return .bool(l != r)
            default:
                typeCheckerMissed()
            }
        case .lt:
            switch (lhs, rhs) {
            case let (.int(l), .int(r)):
                return .bool(l < r)
            case let (.float(l), .float(r)):
                return .bool(l < r)
            case let (.float(l), .int(r)):
                return .bool(l < Double(r))
            case let (.int(l), .float(r)):
                return .bool(Double(l) < r)
            default:
                typeCheckerMissed()
            }
        case .ltOrEq:
            switch (lhs, rhs) {
            case let (.int(l), .int(r)):
                return .bool(l <= r)
            case let (.float(l), .float(r)):
                return .bool(l <= r)
            case let (.float(l), .int(r)):
                return .bool(l <= Double(r))
            case let (.int(l), .float(r)):
                return .bool(Double(l) <= r)
            default:
                typeCheckerMissed()
            }
        case .gt:
            switch (lhs, rhs) {
            case let (.int(l), .int(r)):
                return .bool(l > r)
            case let (.float(l), .float(r)):
                return .bool(l > r)
            case let (.float(l), .int(r)):
                return .bool(l > Double(r))
            case let (.int(l), .float(r)):
                return .bool(Double(l) > r)
            default:
                typeCheckerMissed()
            }
        case .gtOrEq:
            switch (lhs, rhs) {
            case let (.int(l), .int(r)):
                return .bool(l >= r)
            case let (.float(l), .float(r)):
                return .bool(l >= r)
            case let (.float(l), .int(r)):
                return .bool(l >= Double(r))
            case let (.int(l), .float(r)):
                return .bool(Double(l) >= r)
            default:
                typeCheckerMissed()
            }
        }
    }
    
    private func storage(for expr: Expr) throws -> Storage<Value>? {
        switch expr {
        case let ident as IdentExpr:
            return scope.storage(ident: ident.ident)
        case let sub as SubScriptExpr:
            guard case let .int(index) = try sub.index.accept(visitor: self) else {
                return nil
            }
            
            return try storage(for: sub.value)?.at(index: index)
        default:
            // TODO: Throw error
            return nil
        }
    }
}

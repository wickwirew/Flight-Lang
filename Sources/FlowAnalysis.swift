//
//  FlowAnalysis.swift
//  
//
//  Created by wes on 8/14/23.
//

struct FlowAnalysis: StmtVisitor {
    let errors: ErrorHandler
    
    enum Result {
        case returns
        case none
        
        func merging(_ other: Result) -> Result {
            switch (self, other) {
            case (.returns, .returns): return .returns
            default: return .none
            }
        }
    }
    
    func validatePaths(function: FunctionStmt) throws {
        guard function.returnType != .void else { return }
        
        let result = try function.accept(visitor: self)
        
        switch result {
        case .returns:
            break // All good
        case .none:
            errors.add(.notAllCodePathsReturnAValue, at: function.location)
        }
    }
    
    func visit(function: FunctionStmt) throws -> Result {
        return try function.body.accept(visitor: self)
    }
    
    func visit(return: ReturnStmt) throws -> Result {
        return .returns
    }
    
    func visit(`let`: LetStmt) throws -> Result {
        return .none
    }
    
    func visit(expr: ExprStmt) throws -> Result {
        return .none
    }
    
    func visit(body: BodyStmt) throws -> Result {
        for stmt in body.stmts {
            let r = try stmt.accept(visitor: self)
            
            switch r {
            case .returns:
                return .returns
            case .none:
                break
            }
        }
        
        return .none
    }
    
    func visit(if: IfStmt) throws -> Result {
        let main = try `if`.body.accept(visitor: self)
        
        switch `if`.else {
        case .else(let body):
            let res = try body.accept(visitor: self)
            return main.merging(res)
        case .elseIf(let elIf):
            let res = try elIf.accept(visitor: self)
            return main.merging(res)
        case nil:
            // No else, it cannot always return
            return .none
        }
    }
    
    func visit(while: WhileStmt) throws -> Result {
        return try `while`.body.accept(visitor: self)
    }
    
    func visit(for: ForStmt) throws -> Result {
        return try `for`.body.accept(visitor: self)
    }
}

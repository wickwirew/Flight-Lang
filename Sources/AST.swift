//
//  AST.swift
//  
//
//  Created by wes on 8/11/23.
//

protocol Stmt {
    var location: SourceLocation { get }
    func accept<V: StmtVisitor>(visitor: V) throws -> V.StmtOutput
}

protocol Expr {
    var location: SourceLocation { get }
    func accept<V: ExprVisitor>(visitor: V) throws -> V.ExprOutput
}

typealias Ident = String

struct FunctionStmt: Stmt {
    let ident: Ident
    let params: [(Ident, Type)]
    let returnType: Type
    let location: SourceLocation
    let body: BodyStmt
    
    func accept<V: StmtVisitor>(visitor: V) throws -> V.StmtOutput {
        return try visitor.visit(function: self)
    }
}

struct ReturnStmt: Stmt {
    let result: Expr
    let location: SourceLocation
    
    func accept<V: StmtVisitor>(visitor: V) throws -> V.StmtOutput {
        return try visitor.visit(return: self)
    }
}

struct LetStmt: Stmt {
    let ident: Ident
    let expr: Expr
    let location: SourceLocation
    
    func accept<V: StmtVisitor>(visitor: V) throws -> V.StmtOutput {
        return try visitor.visit(let: self)
    }
}

struct ExprStmt: Stmt {
    let expr: Expr
    
    var location: SourceLocation {
        return expr.location
    }
    
    func accept<V: StmtVisitor>(visitor: V) throws -> V.StmtOutput {
        return try visitor.visit(expr: self)
    }
}

struct IfStmt: Stmt {
    let condition: Expr
    let body: BodyStmt
    let `else`: Else?
    let location: SourceLocation
    
    enum Else {
        case `else`(BodyStmt)
        indirect case elseIf(IfStmt)
    }
    
    func accept<V: StmtVisitor>(visitor: V) throws -> V.StmtOutput {
        return try visitor.visit(if: self)
    }
}

struct BodyStmt: Stmt {
    let stmts: [Stmt]
    let location: SourceLocation
    
    func accept<V: StmtVisitor>(visitor: V) throws -> V.StmtOutput {
        return try visitor.visit(body: self)
    }
}

struct WhileStmt: Stmt {
    let condition: Expr
    let body: BodyStmt
    
    var location: SourceLocation {
        return condition.location
    }
    
    func accept<V>(visitor: V) throws -> V.StmtOutput where V : StmtVisitor {
        return try visitor.visit(while: self)
    }
}

struct ForStmt: Stmt {
    let variable: Ident
    let lowerBound: Expr
    let upperBound: Expr
    let location: SourceLocation
    let body: BodyStmt
    
    func accept<V>(visitor: V) throws -> V.StmtOutput where V : StmtVisitor {
        return try visitor.visit(for: self)
    }
}

struct IntLit: Expr {
    let int: Int
    let location: SourceLocation
    
    func accept<V: ExprVisitor>(visitor: V) throws -> V.ExprOutput {
        return try visitor.visit(int: self)
    }
}

struct FloatLit: Expr {
    let float: Double
    let location: SourceLocation
    
    func accept<V: ExprVisitor>(visitor: V) throws -> V.ExprOutput {
        return try visitor.visit(float: self)
    }
}

struct StringLit: Expr {
    let string: String
    let location: SourceLocation
    
    func accept<V: ExprVisitor>(visitor: V) throws -> V.ExprOutput {
        return try visitor.visit(string: self)
    }
}

struct BoolLit: Expr {
    let bool: Bool
    let location: SourceLocation
    
    func accept<V: ExprVisitor>(visitor: V) throws -> V.ExprOutput {
        return try visitor.visit(bool: self)
    }
}

struct ArrayLit: Expr {
    let values: [Expr]
    let location: SourceLocation
    
    func accept<V: ExprVisitor>(visitor: V) throws -> V.ExprOutput {
        return try visitor.visit(array: self)
    }
}

struct IdentExpr: Expr {
    let ident: Ident
    let location: SourceLocation
    
    func accept<V: ExprVisitor>(visitor: V) throws -> V.ExprOutput {
        return try visitor.visit(ident: self)
    }
}

struct CallExpr: Expr {
    let function: Ident
    let args: [Expr]
    let location: SourceLocation
    
    func accept<V: ExprVisitor>(visitor: V) throws -> V.ExprOutput {
        return try visitor.visit(call: self)
    }
}

struct SubScriptExpr: Expr {
    let value: Expr
    let index: Expr
    
    var location: SourceLocation {
        return value.location.spanning(index.location)
    }
    
    func accept<V: ExprVisitor>(visitor: V) throws -> V.ExprOutput {
        return try visitor.visit(subscript: self)
    }
}

struct InfixExpr: Expr {
    let lhs: Expr
    let `operator`: Operator
    let rhs: Expr
    
    var location: SourceLocation {
        return lhs.location.spanning(rhs.location)
    }
    
    func accept<V: ExprVisitor>(visitor: V) throws -> V.ExprOutput {
        return try visitor.visit(infix: self)
    }
}

struct AssignExpr: Expr {
    let receiver: Expr
    let value: Expr
    let location: SourceLocation

    func accept<V>(visitor: V) throws -> V.ExprOutput where V : ExprVisitor {
        return try visitor.visit(assign: self)
    }
}

protocol StmtVisitor {
    associatedtype StmtOutput
    func visit(function: FunctionStmt) throws -> StmtOutput
    func visit(return: ReturnStmt) throws -> StmtOutput
    func visit(`let`: LetStmt) throws -> StmtOutput
    func visit(expr: ExprStmt) throws -> StmtOutput
    func visit(body: BodyStmt) throws -> StmtOutput
    func visit(if: IfStmt) throws -> StmtOutput
    func visit(while: WhileStmt) throws -> StmtOutput
    func visit(for: ForStmt) throws -> StmtOutput
}

protocol ExprVisitor {
    associatedtype ExprOutput
    func visit(int: IntLit) throws -> ExprOutput
    func visit(float: FloatLit) throws -> ExprOutput
    func visit(string: StringLit) throws -> ExprOutput
    func visit(bool: BoolLit) throws -> ExprOutput
    func visit(array: ArrayLit) throws -> ExprOutput
    func visit(ident: IdentExpr) throws -> ExprOutput
    func visit(call: CallExpr) throws -> ExprOutput
    func visit(infix: InfixExpr) throws -> ExprOutput
    func visit(assign: AssignExpr) throws -> ExprOutput
    func visit(subscript: SubScriptExpr) throws -> ExprOutput
}

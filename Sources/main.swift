import ArgumentParser
import Foundation

struct Build: ParsableCommand {
    public static var configuration = CommandConfiguration(
        abstract: "Build the list of source files."
    )

    @Argument(help: "A list of files to compile")
    var files: [String]

    func run() {
        let wd = FileManager.default.currentDirectoryPath
        let errors = ErrorHandler()
        var stmts: [Stmt] = []
        
        do {
            for file in files {
                let fullPath = "\(wd)/\(file)"
                let source = try String(contentsOfFile: fullPath)
                let lexer = Lexer(fileName: fullPath, source: source, errors: errors)
                let parser = Parser(lexer: lexer, errors: errors)
                stmts.append(contentsOf: parser.parse())
            }
            
            let typeChecker = TypeChecker(stmts: stmts, errors: errors)
            try typeChecker.check()
            try errors.validate()
            let interpreter = try Interpreter(stmts: stmts)
            try interpreter.execute()
        } catch {
            print(error)
        }
    }
}

struct Flight: ParsableCommand {
    static var configuration = CommandConfiguration(
        abstract: "A language made in a flight/vacation",
        subcommands: [Build.self],
        defaultSubcommand: Build.self
    )
}

Flight.main()

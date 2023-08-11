//
//  ErrorHandler.swift
//  
//
//  Created by wes on 8/12/23.
//

class ErrorHandler {
    private var errors: [(error: FlightError, location: SourceLocation)] = []
    
    struct AggregatedErrors: Error, CustomStringConvertible {
        let messages: [String]
        
        var description: String {
            messages.joined(separator: "\n\n")
        }
    }
    
    @discardableResult
    func add(_ error: FlightError, at location: SourceLocation) -> FlightError {
        errors.append((error, location))
        return error
    }
    
    @discardableResult
    func add(_ error: FlightError, for token: Token) -> FlightError {
        return add(error, at: token.location)
    }
    
    public func validate() throws {
        guard !errors.isEmpty else { return }
        
        var messages: [String] = []
        
        for (error, location) in errors {
            let source = try String(contentsOfFile: location.file)
            let range = location.range
            let startOfLine = startOfLine(in: source, on: range.lowerBound)
            let endOfLine = endOfLine(in: source, on: range.lowerBound)
            let line = lineNumberOf(index: range, in: source)
            let charsFromStart = source.distance(from: startOfLine, to: range.lowerBound)
            let errorChars = source.distance(from: range.lowerBound, to: range.upperBound)
            let spacing = String(repeating: " ", count: charsFromStart)
            let underline = String(repeating: "^", count: errorChars)
            let fileName = location.file.split(separator: "/").last ?? ""

            let descriptor = "\(fileName):\(line):\(charsFromStart + 1)"

            messages.append("""
            \(descriptor): \(error.description)
            \(source[startOfLine..<endOfLine].map(\.description).joined())
            \(spacing)\(underline)
            """)
        }
        
        throw AggregatedErrors(messages: messages)
    }
    
    private func lineNumberOf(index: Range<String.Index>, in source: String) -> Int {
        var line = 1
        let offset = index.lowerBound.utf16Offset(in: source)
        
        for (i, char) in source.enumerated() {
            if char == "\n" {
                line += 1
            }
            
            if i > offset {
                return line
            }
        }
        
        return line
    }
    
    private func startOfLine(in source: String, on index: String.Index) -> String.Index {
        guard index != source.startIndex else { return index }
        
        var result = index
        
        var next = source.index(before: result)
        while result != source.startIndex && source[next] != "\n" {
            result = next
            next = source.index(before: result)
        }
        
        return result
    }
    
    private func endOfLine(in source: String, on index: String.Index) -> String.Index {
        var result = index
        
        while result < source.endIndex && source[result] != "\n" {
            result = source.index(after: result)
        }
        
        return result
    }
}

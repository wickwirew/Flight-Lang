//
//  Scope.swift
//  
//
//  Created by wes on 8/12/23.
//

struct Storage<V> {
    let read: () -> V?
    let write: (V) -> Void
}

extension Storage where V == Value {
    func at(index: Int) -> Self {
        return Storage {
            switch read() {
            case let .array(array):
                return array[index]
            case let .string(string):
                let sIndex = string.index(string.startIndex, offsetBy: index)
                return .string(string[sIndex].description)
            default:
                return nil
            }
        } write: { newValue in
            switch read() {
            case var .array(array):
                array[index] = newValue
                write(.array(array))
            case var .string(string):
                guard case let .string(stringToInsert) = newValue else { return }
                let sIndex = string.index(string.startIndex, offsetBy: index)
                string.insert(contentsOf: stringToInsert, at: sIndex)
                write(.string(string))
            default:
                break
            }
            
        }
    }
}

class Scope<V> {
    let context: Context?
    private var values: [Ident: V]
    private var parent: Scope?
    
    enum Context {
        case fn(returnType: Type)
    }
    
    init(
        values: [Ident : V],
        context: Context? = nil,
        parent: Scope? = nil
    ) {
        self.values = values
        self.context = context
        self.parent = parent
    }
    
    func pushing(context: Context? = nil) -> Scope<V> {
        return Scope(values: [:], context: context, parent: self)
    }
    
    func popping() -> Scope<V> {
        guard let parent else {
            fatalError("Cannot pop global scope")
        }
        
        return parent
    }
    
    func insert(ident: Ident, value: V) {
        values[ident] = value
    }
    
    func get(ident: Ident, checkParent: Bool = true) -> V? {
        if let value = values[ident] {
            return value
        } else if checkParent {
            return parent?.get(ident: ident)
        } else {
            return nil
        }
    }
    
    func update(ident: Ident, value: V) {
        if values[ident] != nil {
            values[ident] = value
        } else {
            parent?.update(ident: ident, value: value)
        }
    }
    
    func storage(ident: Ident) -> Storage<V> {
        return Storage {
            return self.get(ident: ident)
        } write: { newValue in
            self.update(ident: ident, value: newValue)
        }
    }
}


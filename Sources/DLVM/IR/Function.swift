//
//  Intrinsics.swift
//  DLVM
//
//  Created by Richard Wei on 2/13/17.
//
//

public final class Function : Named, IRCollection, IRSubUnit {
    public enum Attribute {
        case differentiable
        case inline
        case differentiating(Function)
    }

    public typealias Element = BasicBlock

    public var name: String
    public var result: Type
    public var arguments: OrderedMapSet<Argument> = []
    public var attributes: Set<Attribute> = []
    public unowned var parent: Module

    public var elements: OrderedMapSet<BasicBlock> = []
    public internal(set) var analysisManager: AnalysisManager<Function> = AnalysisManager()
    public internal(set) var transformManager: TransformManager<Function> = TransformManager()

    public unowned var entry: BasicBlock {
        if let entry = elements["entry"] {
            return entry
        }
        let bb = BasicBlock(asEntryOf: self)
        elements.append(bb)
        return bb
    }

    public init(name: String, arguments: [(String, Type)],
                result: Type, attributes: Set<Attribute>, parent: Module) {
        self.name = name
        self.arguments.append(contentsOf: arguments.map(Argument.init))
        self.result = result
        self.attributes = attributes
        self.parent = parent
        _ = entry
    }
}

// MARK: - Hashable
extension Function.Attribute : Hashable {
    public static func == (lhs: Function.Attribute, rhs: Function.Attribute) -> Bool {
        switch (lhs, rhs) {
        /// Equality by case handle
        case (.differentiable, .differentiable),
             (.inline, .inline),
             (.differentiating, .differentiating):
            return true
        default:
            return false
        }
    }
    
    public var hashValue: Int {
        switch self {
        case .differentiable:  return 1.hashValue
        case .inline:          return 2.hashValue
        case .differentiating: return 3.hashValue
        }
    }
}

// MARK: - Attribute helper
extension Function {
    public var isDifferentiable: Bool {
        return attributes.contains(.differentiable)
    }
}

// MARK: - Value
extension Function : Value, Definition {
    public var type: Type {
        return .function(arguments.map{$0.type}, result)
    }

    public func makeUse() -> Use {
        return .function(type, self)
    }
}

// MARK: - Arguments
public extension Function {

    func acceptsArguments<C : Collection>(_ types: C) -> Bool where C.Iterator.Element == Type {
        return types.elementsEqual(arguments.map{$0.type})
    }

    func argument(named name: String) -> Argument? {
        return arguments.element(named: name)
    }

    func argumentValue(named name: String) -> Use? {
        return argument(named: name).flatMap { .argument($0.type, $0) }
    }

    func containsArgument(named name: String) -> Bool {
        return arguments.containsElement(named: name)
    }
    
}

// MARK: - Control flow
extension Function {

    open var instructions: LazyCollection<FlattenBidirectionalCollection<Function>> {
        return lazy.joined()
    }

    open func instruction(named name: String) -> Instruction? {
        for bb in self {
            if let inst = bb.element(named: name) {
                return inst
            }
        }
        return nil
    }

    open func containsInstruction(named name: String) -> Bool {
        return instruction(named: name) != nil
    }

    open func containsName(_ name: String) -> Bool {
        return containsElement(named: name) || contains(where: {
            $0.containsArgument(named: name) || $0.containsElement(named: name)
        })
    }

}

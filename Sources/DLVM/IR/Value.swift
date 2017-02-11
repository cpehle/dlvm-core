//
//  Value.swift
//  DLVM
//
//  Created by Richard Wei on 1/10/17.
//
//

public protocol User {
    var operands: [Use] { get }
}

public protocol Usee : class {
    associatedtype UserType : User
    var users: NamedObjectSet<UserType> { get }
}

internal protocol ManagedUsee : Usee {
    var users: NamedObjectSet<UserType> { get set }
}

internal extension ManagedUsee {
    func addUser(_ user: UserType) {
        users.insert(user)
    }

    func removeUser(_ user: UserType) {
        users.remove(user)
    }

    func removeAllUsers() {
        users.removeAll()
    }
}

public protocol Value {
    var shape: TensorShape { get }
    var type: DataType { get }
}

public enum Literal {
    case scalar(ScalarLiteral)
    case tensor(TensorLiteral)
}

public enum ScalarLiteral {
    case int(Int), float(Double), bool(Bool)

    public var typeBase: DataType.Base {
        switch self {
        case .bool: return .bool
        case .int: return .int
        case .float: return .float
        }
    }
}

public enum TensorLiteral {
    case elements([LiteralValue])
    case random(from: LiteralValue, to: LiteralValue)
    case repeating(LiteralValue)

    public var typeBase: DataType.Base {
        switch self {
        case let .elements(elements):
            return elements[0].type.base
        case let .random(from: lowerbound, to: _):
            return lowerbound.type.base
        case let .repeating(value):
            return value.type.base
        }
    }
}

public struct LiteralValue : Value {
    public var type: DataType
    public var shape: TensorShape
    public var literal: ScalarLiteral
}

public protocol Named {
    var name: String { get set }
}

public struct GlobalValue : Named, Value {
    public enum Kind {
        case variable, constant
    }
    public var name: String
    public var kind: Kind
    public var shape: TensorShape
    public var type: DataType
    public var initializer: Literal
}

public struct Placeholder : Value, Named {
    public var name: String
    public var shape: TensorShape
    public var type: DataType
}

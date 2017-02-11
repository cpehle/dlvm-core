//
//  Instruction.swift
//  DLVM
//
//  Created by Richard Wei on 12/25/16.
//
//

///
/// ## Functions
///

public enum LogicOperator {
    case and, or, xor
}

public enum ComparisonPredicate {
    case lessThan, lessThanOrEqualTo
    case greaterThan, greaterThanOrEqualTo
    case equalTo, notEqualTo
}

public enum ArithmeticOperator {
    case add, subtract, multiply, divide, min, max
    case truncateDivide, floorDivide, modulo, power, mean
}

public enum ElementwiseFunction {
    case sigmoid, tanh
    case log, exp, neg, sign, square, sqrt, round, rsqrt, ceil, floor
    case tan, cos, sin, acos, asin, atan
    case lgamma, digamma, erf, erfc, rint
}

public enum ReductionFunction {
    case logical(LogicOperator)
    case arithmetic(ArithmeticOperator)
}

public enum IntegrationFunction {
    case softmax, logSoftmax, argmax, argmin
    case scan(ReductionFunction)
}

public class Def<T : Value> : ManagedUsee, Named {
    public typealias UserType = Instruction
    public var name: String
    public var shape: TensorShape
    public var type: DataType
    public var value: T
    public var users: NamedObjectSet<Instruction> = []
    public init(name: String, value: T) {
        self.name = name
        self.shape = value.shape
        self.type = value.type
        self.value = value
    }
}

public struct Use {
    public enum Kind {
        case local(Def<Operation>)
        case global(Def<GlobalValue>)
        case literal(LiteralValue)
    }
    public var shape: TensorShape
    public var type: DataType
    public var kind: Kind

    public init(shape: TensorShape, type: DataType, kind: Kind) {
        self.shape = shape
        self.type = type
        self.kind = kind
    }

    public init(kind: Kind) {
        switch kind {
        case .local(let def):
            self.init(shape: def.shape, type: def.type, kind: kind)
        case .global(let def):
            self.init(shape: def.shape, type: def.type, kind: kind)
        case .literal(let lit):
            self.init(shape: lit.shape, type: lit.type, kind: kind)
        }
    }
}

public enum Instruction {
    case control(Control)
    case operation(Def<Operation>)
}

public enum Control {
    case store(Use, to: GlobalValue)
    case export(Use, to: GlobalValue)
    case br(BasicBlock)
    case condBr(Use, BasicBlock, BasicBlock)
    case ret
}

public enum Operation {
    case load(Placeholder)
    case compare(ComparisonPredicate, Use, Use)
    case reduce(ReductionFunction, Use, axis: Int?)
    case arithmetic(ArithmeticOperator, Use, Use)
    case logical(LogicOperator, Use, Use)
    case integrate(IntegrationFunction, Use)
    case transform(ElementwiseFunction, Use)
    case matrixMultiply(Use, Use)
    case concat([Use], axis: Int)
    case phi([(Use, BasicBlock)])
    case typeCast(Use, DataType)
    case shapeCast(Use, TensorShape)
}

extension Operation : Value {

    public var type: DataType {
        switch self {
        case let .arithmetic(_, op1, _),
             let .compare(_, op1, _),
             let .logical(_, op1, _),
             let .matrixMultiply(op1, _):
            return op1.type
        case let .integrate(_, op),
             let .transform(_, op),
             let .reduce(_, op, _):
            return op.type
        case let .phi(ops):
            return ops[0].0.type
        case let .concat(ops, _):
            return ops[0].type
        case let .typeCast(_, t):
            return t
        case let .shapeCast(op, _):
            return op.type
        }
    }

    public var shape: TensorShape {
        switch self {
        case let .arithmetic(_, op1, _),
             let .compare(_, op1, _),
             let .logical(_, op1, _),
             let .matrixMultiply(op1, _):
            return op1.shape
        case let .integrate(_, op),
             let .transform(_, op),
             let .reduce(_, op, _):
            return op.shape
        case let .phi(ops):
            return ops[0].0.shape
        case let .concat(ops, _):
            return ops[0].shape
        case let .typeCast(op, _):
            return op.shape
        case let .shapeCast(_, s):
            return s
        }
    }

}

extension Control : User {
    public var operands: [Use] {
        switch self {
        case .condBr(let op, _, _),
             .export(let op, _),
             .store(let op, _):
            return [op]
        default:
            return []
        }
    }
}

extension Operation : User {
    public var operands: [Use] {
        switch self {
        case let .arithmetic(_, op1, op2),
             let .compare(_, op1, op2),
             let .logical(_, op1, op2),
             let .matrixMultiply(op1, op2):
            return [op1, op2]
        case .concat(let uses, axis: _):
            return uses
        case let .transform(_, op),
             let .integrate(_, op),
             let .reduce(_, op, _),
             let .shapeCast(op, _),
             let .typeCast(op, _):
            return [op]
        case let .phi(incomings):
            return incomings.map{$0.0}
        case .load(_):
            return []
        }
    }
}

extension Instruction : User {
    public var operands: [Use] {
        switch self {
        case .control(let ctrl): return ctrl.operands
        case .operation(let oper): return oper.operands
        }
    }
}

public extension Def where T : User {
    public var operands: [Use] {
        return value.operands
    }
}

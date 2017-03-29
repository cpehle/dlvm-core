//
// Created by Richard Wei on 12/25/16.
//

import DLVMTensor

extension LiteralValue : TextOutputStreamable {
    public func write<Target : TextOutputStream>(to target: inout Target) {
        target.write("\(literal) : \(type)")
    }
}

extension ScalarLiteral : TextOutputStreamable {
    public func write<Target : TextOutputStream>(to target: inout Target) {
        switch self {
        case let .bool(b): target.write(b.description)
        case let .int(i): target.write(i.description)
        case let .float(f): target.write(f.description)
        }
    }
}

extension Literal : TextOutputStreamable {
    public func write<Target : TextOutputStream>(to target: inout Target) {
        switch self {
        case let .scalar(lit):
            lit.write(to: &target)
        case let .tensor(vals):
            target.write("[\(vals.joinedDescription)]")
        case let .tuple(vals):
            target.write("(\(vals.joinedDescription))")
        case let .array(vals):
            target.write("<\(vals.joinedDescription)>")
        case .zero:
            target.write("zero")
        case .undefined:
            target.write("undefined")
        }
    }
}

extension TensorShape : TextOutputStreamable {
    public func write<Target : TextOutputStream>(to target: inout Target) {
        target.write("\(map{String($0)}.joined(separator: "x"))")
    }
}

extension TensorIndex : TextOutputStreamable {
    public func write<Target : TextOutputStream>(to target: inout Target) {
        target.write("(")
        joinedDescription.write(to: &target)
        target.write(")")
    }
}

extension Type : TextOutputStreamable {
    public func write<Target>(to target: inout Target) where Target : TextOutputStream {
        target.write("$")
        switch self {
        case .invalid:
            target.write("<<error>>")
        case let .tensor([], t):
            t.write(to: &target)
        case let .tensor(s, t):
            target.write("[\(s) x \(t)]")
        case let .tuple(subtypes):
            target.write("(\(subtypes.joinedDescription))")
        case .void:
            target.write("void")
        case let .array(subtype, n):
            target.write("<\(n) x \(subtype)>")
        case let .pointer(subtype):
            target.write("\(subtype)*")
        case let .function(args, ret):
            target.write("(\(args.joinedDescription) -> \(ret))")
        case let .alias(a):
            a.name.write(to: &target)
        }
    }
}

extension DataType.Base : TextOutputStreamable {
    public func write<Target : TextOutputStream>(to target: inout Target) {
        switch self {
        case .float: target.write("f")
        case .int: target.write("i")
        case .bool: target.write("b")
        }
    }
}

extension DataType : TextOutputStreamable {
    public func write<Target : TextOutputStream>(to target: inout Target) {
        switch self {
        case .bool: target.write("bool")
        case let .int(w): target.write("i\(w)")
        case let .float(w): target.write("f\(w.rawValue)")
        }
    }
}

extension AssociativeOp: TextOutputStreamable {
    public func write<Target : TextOutputStream>(to target: inout Target) {
        switch self {
        case let .arithmetic(fun): String(describing: fun).write(to: &target)
        case let .boolean(fun): String(describing: fun).write(to: &target)
        }
    }
}

extension BinaryOp: TextOutputStreamable {
    public func write<Target : TextOutputStream>(to target: inout Target) {
        switch self {
        case let .associative(fun): fun.write(to: &target)
        case let .comparison(fun): String(describing: fun).write(to: &target)
        }
    }
}

extension UnaryOp: TextOutputStreamable {
    public func write<Target : TextOutputStream>(to target: inout Target) {
        switch self {
        case let .elementwise(fun): String(describing: fun).write(to: &target)
        }
    }
}

extension InstructionKind : TextOutputStreamable {
    public func write<Target : TextOutputStream>(to target: inout Target) {
        switch self {
        case let .branch(bb, args):
            target.write("branch %\(bb.name)(\(args.joinedDescription))")
        case let .conditional(op, thenBB, thenArgs, elseBB, elseArgs):
            target.write("conditional \(op) then %\(thenBB.name)(\(thenArgs.joinedDescription)) else %\(elseBB.name)(\(elseArgs.joinedDescription))")
        case let .`return`(op):
            target.write("return")
            if let op = op { target.write(" \(op)") }
        case let .binary(f, op1, op2):
            target.write("\(f) \(op1), \(op2)")
        case let .matrixMultiply(op1, op2):
            target.write("matrixMultiply \(op1), \(op2)")
        case let .unary(f, op):
            target.write("\(f) \(op)")
        case let .reduce(f, op, axis: axis):
            target.write("reduce \(f) \(op)")
            if let axis = axis {
                target.write(" along \(axis)")
            }
        case let .scan(f, op, axis: axis):
            target.write("scan \(f) \(op)")
            if let axis = axis {
                target.write(" along \(axis)")
            }
        case let .concatenate(ops, axis: axis):
            target.write("concatenate \(ops.map{"\($0)"}.joined(separator: ", ")) along \(axis)")
        case let .transpose(op):
            target.write("transpose \(op)")
        case let .dataTypeCast(op, t):
            target.write("dataTypeCast \(op) to \(t)")
        case let .shapeCast(op, s):
            target.write("shapeCast \(op) to \(s)")
        case let .call(f, args):
            target.write("call \(f)(\(args.map{"\($0)"}.joined(separator: ", ")))")
        case let .gradient(f, args):
            target.write("gradient \(f)(\(args.map{"\($0)"}.joined(separator: ", ")))")
        case let .extract(use, indices):
            target.write("extract \(use) at \(indices.map{"\($0)"}.joined(separator: ", "))")
        case let .insert(src, to: dest, at: indices):
            target.write("insert \(src) to \(dest) at \(indices.map{"\($0)"}.joined(separator: ", "))")
        case let .allocate(t, n):
            target.write("allocate \(t), \(n)")
        case let .store(v, p):
            target.write("store \(v) to \(p)")
        case let .load(v):
            target.write("load \(v)")
        case let .elementPointer(v, i):
            target.write("elementPointer \(v), \(i)")
        case let .bitCast(v, t):
            target.write("bitCast \(v) to \(t)")
        }
    }
}

extension Instruction : TextOutputStreamable {
    public func write<Target : TextOutputStream>(to target: inout Target) {
        if let name = name {
            target.write("%\(name) = ")
        }
        kind.write(to: &target)
    }
}

extension GlobalValue : TextOutputStreamable {
    public func write<Target : TextOutputStream>(to target: inout Target) {
        switch kind {
        case .variable: target.write("var ")
        case .constant: target.write("const ")
        }
        target.write("\(kind) @\(name) ")
        target.write(": \(type) = \(initializer)\n")
    }
}

extension TypeAlias : TextOutputStreamable {
    public func write<Target>(to target: inout Target) where Target : TextOutputStream {
        switch self {
        case let .opaque(name):
            target.write("type $\(name) = opaque")
        case let .transparent(name, ty):
            target.write("type $\(name) = \(ty)")
        }
    }
}

extension Use : TextOutputStreamable {
    public func write<Target : TextOutputStream>(to target: inout Target) {
        switch self {
        case let .global(_, ref):      target.write("@\(ref.name)")
        case let .instruction(_, ref): target.write(ref.name.flatMap{"%\($0)"} ?? "%_")
        case let .argument(_, ref):    target.write("%\(ref.name)")
        case let .literal(_, lit):     lit.literal.write(to: &target)
        case let .function(_, ref):    target.write("@\(ref.name)")
        }
        target.write(" : \(type)")
    }
}

extension BasicBlock : TextOutputStreamable {
    private func makeIndentation() -> String {
        return "    "
    }

    public func write<Target : TextOutputStream>(to target: inout Target) {
        /// Begin block
        target.write("\(name)(\(arguments.map{"\($0)"}.joined(separator: ", "))):\n")
        for inst in elements {
            /// Write indentation
            makeIndentation().write(to: &target)
            inst.write(to: &target)
            target.write("\n")
        }
    }
}

extension Argument : TextOutputStreamable {
    public func write<Target>(to target: inout Target) where Target : TextOutputStream {
        target.write("%\(name) : \(type)")
    }
}

extension Function.Attribute : TextOutputStreamable {
    public func write<Target>(to target: inout Target) where Target : TextOutputStream {
        target.write("!")
        switch self {
        case .differentiable: target.write("differentiable")
        case .inline: target.write("inline")
        case .differentiating(let f): target.write("differentiating(@\(f.name))")
        }
    }
}

extension Function : TextOutputStreamable {
    public func write<Target : TextOutputStream>(to target: inout Target) {
        for attr in attributes {
            attr.write(to: &target)
            target.write("\n")
        }
        target.write("func ")
        target.write("@\(name)(")
        arguments.map{"\($0)"}.joined(separator: ", ").write(to: &target)
        target.write(") ")
        if !result.isVoid {
            target.write("-> \(result) ")
        }
        target.write("{\n")
        for bb in self {
            bb.write(to: &target)
        }
        target.write("}")
    }
}

extension Module : TextOutputStreamable {

    public func write<Target : TextOutputStream>(to target: inout Target) {
        target.write("module \(name)\n\n")
        target.write(typeAliases.map{"\($0)"}.joined(separator: "\n"))
        target.write("\n")
        target.write(globalValues.map{"\($0)"}.joined(separator: "\n"))
        target.write("\n")
        for fun in self {
            fun.write(to: &target)
            target.write("\n\n")
        }
    }
}

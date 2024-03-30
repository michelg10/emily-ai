indirect enum ActionDataType {
    case array(of: ActionDataType)
    case optional(of: ActionDataType)
    case int
    case double
    case bool
    case string
    
    func describe() -> String {
        switch self {
        case .array(let innerType):
            return "[\(innerType.describe())]"
        case .optional(let innerType):
            return "\(innerType.describe())?"
        case .int:
            return "Int"
        case .double:
            return "Double"
        case .bool:
            return "Bool"
        case .string:
            return "String"
        }
    }
}

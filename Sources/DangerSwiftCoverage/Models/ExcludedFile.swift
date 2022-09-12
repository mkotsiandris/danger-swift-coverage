import Foundation

public enum ExcludedFile: Equatable {
    case exact(String)
    case prefix(String)
    case suffix(String)
    case regex(String)

    func matches(string: String) -> Bool {
        guard let fileURL = URL(string: string), let fileName = fileURL.pathComponents.last else { return false }
        switch self {
            case let .exact(needle):
                return fileName == needle
            case let .prefix(needle):
                return fileName.hasPrefix(needle)
            case let .suffix(needle):
                return fileName.hasSuffix(needle)
            case let .regex(regex):
                return fileName.range(of: regex, options: .regularExpression) != nil
        }
    }
}

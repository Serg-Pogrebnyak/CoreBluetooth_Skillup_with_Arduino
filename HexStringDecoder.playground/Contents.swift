import UIKit

extension StringProtocol {
    var hexa: [UInt8] {
        var startIndex = self.startIndex
        return stride(from: 0, to: count, by: 2).compactMap { _ in
            let endIndex = index(startIndex, offsetBy: 2, limitedBy: self.endIndex) ?? self.endIndex
            defer { startIndex = endIndex }
            return UInt8(self[startIndex..<endIndex], radix: 16)
        }
    }
}



let hexaString = "3333C341"
let bytes = hexaString.hexa
print("float:\(bytes.withUnsafeBytes { $0.load(as: Float.self) })")
print("string:\(String(bytes: bytes, encoding: .utf8))")

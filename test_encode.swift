import Foundation

struct Dummy: Codable {
    var endDate: Date?

    enum CodingKeys: String, CodingKey {
        case endDate = "end_date"
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        let formatted = endDate.map { _ in "some_date_string" }
        try c.encodeIfPresent(formatted, forKey: .endDate)
    }
}

let d1 = Dummy(endDate: nil)
let d2 = Dummy(endDate: Date())

let enc = JSONEncoder()
enc.outputFormatting = .prettyPrinted

print(String(data: try! enc.encode(d1), encoding: .utf8)!)
print("---")
print(String(data: try! enc.encode(d2), encoding: .utf8)!)

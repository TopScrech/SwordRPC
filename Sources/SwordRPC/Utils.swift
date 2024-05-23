import Foundation

extension SwordRPC {
    func encode(_ value: Any) -> Data {
        do {
            return try JSONSerialization.data(withJSONObject: value, options: [])
        } catch {
            return Data()
        }
    }
    
    func decode(_ json: Data) -> [String: Any] {
        do {
            return try JSONSerialization.jsonObject(with: json, options: []) as! [String: Any]
        } catch {
            return [:]
        }
    }
}

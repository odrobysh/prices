import Foundation

struct AccessTokenDto: Decodable {
    let accessToken: String
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
    }
}

struct Instrument: Decodable {
    let id: String
    let symbol: String
    let description: String
}
struct InstrumentsDto: Decodable {
    let data: [Instrument]
}

struct Quotation: Decodable {
    let timestamp: Date
    let price: Double
}

struct InstrumentUpdateDto: Decodable {
    let ask: Quotation?
    let bid: Quotation?
}

struct SubscribeMessageDto: Encodable {
    let type: String
    let id: String
    let instrumentId: String
    let provider: String
    let subscribe: Bool
    let kinds: [String]
}


struct Bar: Decodable {
    let t: Date
    let o: Double
    let h: Double
    let l: Double
    let c: Double
    let v: Double
}
struct BarsDto: Decodable {
    let data: [Bar]
}

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

public struct Net {
    static let uri = "https://platform.fintacharts.com"
    static var getAccessToken: () async throws -> String = {
        let url = URL(string: "\(uri)/identity/realms/fintatech/protocol/openid-connect/token")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        var bodyComponents = URLComponents()
        bodyComponents.queryItems = [
            .init(name: "grant_type", value: "password"),
            .init(name: "client_id", value: "app-cli"),
            .init(name: "username", value: "r_test@fintatech.com"),
            .init(name: "password", value: "kisfiz-vUnvy9-sopnyv")
        ]
        
        request.httpBody = bodyComponents.query?.data(using: .utf8)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        let fetchedData = try JSONDecoder().decode(AccessTokenDto.self, from: data)
        return fetchedData.accessToken
    }
    
    static var getInstruments: (_ token: String) async throws -> [Instrument] = { token in
        let url = URL(string: "\(uri)/api/instruments/v1/instruments?provider=oanda&kind=forex")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let (data, response) = try await URLSession.shared.data(for: request)
        let fetchedData = try JSONDecoder().decode(InstrumentsDto.self, from: data)
        return fetchedData.data
    }
    
    static var getBars: (_ token: String, _ instrumentId: String) async throws -> [Bar] = { token, instrumentId in
        let url = URL(string: "\(uri)/api/bars/v1/bars/count-back?instrumentId=\(instrumentId)&provider=simulation&interval=1&periodicity=minute&barsCount=10")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let (data, response) = try await URLSession.shared.data(for: request)
        
        let dateFormatter = DateFormatter()
        // dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSSXXXXX"
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssXXXXX"
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(dateFormatter)

        // guard let instrumentUpdate = try decoder.decode(BarsDto.self, from: data) else { return }
        
        let fetchedData = try decoder.decode(BarsDto.self, from: data)
        
        return fetchedData.data
    }
}


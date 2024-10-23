import Foundation
struct AccessTokenDto: Decodable {
    let accessToken: String
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
    }
}

public struct Net {
    let wss = "wss://platform.fintacharts.com/api/streaming/ws/v1/realtime?token="
    static var getAccessToken: () async throws -> String = {
        let uri = "https://platform.fintacharts.com"
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
}


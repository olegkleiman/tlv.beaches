//
//  ContentView.swift
//  tlv.beaches
//
//  Created by Oleg Kleiman on 10/07/2022.
//

import SwiftUI
import SwiftKeychainWrapper
import Alamofire

struct DecodableRefreshTokens: Codable {
    let access_token: String?
    let token_type: String
    let not_before: Int?
    let id_token_expires_in: Int?
    let profile_info: String?
    let scope: String?
    let expires_in: Int // Here Azure return int in contrast with string within token response
    let expires_on: Int?
    let resource: String?
    let refresh_token: String
    let refresh_token_expires_in: Int?
    let id_token: String
}

struct StrictDecodableTokens: Codable {
    let access_token: String
    let token_type: String
    let expires_in: String
    let refresh_token: String
    let id_token: String
}


struct DecodableTokens: Codable {
    let access_token: String
    let token_type: String
    let expires_in: String
    let refresh_token: String
    let id_token: String
    let sso_token: String?
}

struct ContentView: View {
    
    @State private var pageNum: Int = 1
    @State private var userId: String = "313069486"
    @State private var phoneNumber: String = "0543307026"
    @State private var clientId: String = "8739c7f1-e812-4461-b9c8-d670307dd22b"
    @State private var jsonTokens: DecodableTokens?
    
    var body: some View {
        ScrollView {
            VStack(alignment: .center) {
                Text("TLV Sea Beaches")
                    .font(.largeTitle)
                    .foregroundColor(.pink)

                Group {
                    switch pageNum {
                        case 1:
                            IdentityView(pageNum: $pageNum, phoneNumber: $phoneNumber, userId: $userId, clientId: $clientId)
                        case 2:
                            OTPView(pageNum: $pageNum, phoneNumber: $phoneNumber, userId: $userId, jsonTokens: $jsonTokens, clientId: $clientId)
                        case 3:
                            TokenView(pageNum: $pageNum, jsonTokens: $jsonTokens)
                        default:
                            Text("No action")
                    }
                }

            }
            .onAppear {
                
                guard let ssoToken = KeychainWrapper.standard.string(forKey: "sso_token")
                else {
                    
                    guard let jsonTokensString = KeychainWrapper.standard.string(forKey: "tlv_tokens")
                    else {
                        pageNum = 1
                        return
                    }
                    
                    let data = jsonTokensString.data(using: .utf8)!
                    
                    do {
                        let jsonDecoder = JSONDecoder()
                        self.jsonTokens = try jsonDecoder.decode(DecodableTokens.self, from: data)
                        pageNum = 3
                    } catch let error {
                        print("Tokens deserialization error: \(error)")
                    }
                    
                    return
                }

                let url = "https://tlvsso.azurewebsites.net/api/sso?code=FZunTfHFtLGtdIFFnYJ9bDdQEuMXXewWvqGO4F2GOtQyAzFuD4O97w=="

                let deviceId = UIDevice.current.identifierForVendor!.uuidString
                let parameters: [String: String] = [
                    "clientId": clientId,
                    "scope": "openid offline_access https://TlvfpB2CPPR.onmicrosoft.com/\(clientId)/TLV.Digitel.All",
                    "deviceId": deviceId,
                    "ssoToken": ssoToken
                ]
                
                AF.request(url, method: .post, parameters: parameters, encoder: JSONParameterEncoder.default)
                    .responseDecodable(of: StrictDecodableTokens.self) { response in
  
                        switch response.result {
                        case .success(let jsonTokens): do {
                                
                                let jsonEncoder = JSONEncoder()
                                let jsonData = try jsonEncoder.encode(jsonTokens)
                                let jsonString = String(data: jsonData, encoding: String.Encoding.utf8)
                            
                                KeychainWrapper.standard.set(jsonString!, forKey: "tlv_tokens")
                                self.pageNum = 3
                            
                            } catch  let error {
                                print("🥶 \(error)")
                            }
                            
                            case .failure(let error):
                                print("🥶 \(error)")
                            }
                        
                }

            }
            .padding()
        }

    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .previewInterfaceOrientation(.portraitUpsideDown)
    }
}

//
//  ContentView.swift
//  tlv.beaches
//
//  Created by Oleg Kleiman on 10/07/2022.
//

import SwiftUI
import SwiftKeychainWrapper

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

struct DecodableTokens: Codable {
    let access_token: String
    let token_type: String
    let expires_in: String
    let refresh_token: String
    let id_token: String
}

struct ContentView: View {
    
    @State private var pageNum: Int = 0
    @State private var userId: String = "313069486"
    @State private var phoneNumber: String = "0543307026"
    @State private var jsonTokens: DecodableTokens?
    
    var body: some View {
        VStack {
            Text("TLV Beaches")
                .font(.largeTitle)
                .foregroundColor(.pink)
                .padding(.top, 50)

            Group {
                switch pageNum {
                    case 0:
                        IdentityView(pageNum: $pageNum, phoneNumber: $phoneNumber, userId: $userId)
                    case 1:
                        OTPView(pageNum: $pageNum, phoneNumber: $phoneNumber, userId: $userId, jsonTokens: $jsonTokens)
                    case 2:
                        TokenView(pageNum: $pageNum, jsonTokens: $jsonTokens)
                    default:
                        Text("No action")
                }
    
            }

        }
        .onAppear {
            
            guard let jsonTokensString = KeychainWrapper.standard.string(forKey: "tlv_tokens")
            else {
                pageNum = 0
                return
            }
            
            let data = jsonTokensString.data(using: .utf8)!
            
            do {
                let jsonDecoder = JSONDecoder()
                self.jsonTokens = try jsonDecoder.decode(DecodableTokens.self, from: data)
                pageNum = 2
            } catch let error {
                print("Tokens deserialization error: \(error)")
            }

        }

    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

//
//  ContentView.swift
//  tlv.beaches
//
//  Created by Oleg Kleiman on 10/07/2022.
//

import SwiftUI
import SwiftKeychainWrapper

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

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
    
    @State private var isLoading = false
    
    @ViewBuilder
    var body: some View {
        ScrollView {
            VStack(alignment: .center) {
                Text("TLV Sea Beaches")
                    .font(.largeTitle)
                    .foregroundColor(.pink)

                if( !self.isLoading ) {
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
                } else {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                }

            }
            .onAppear {

                
                let keychainAccessGroupName = "GX7N6F8DFJ.gov.tlv.ssoKeychainGroup"
                let itemKey = "My Key"
                let itemValue = "My secretive bee 🐝"
                
                guard let valueData = itemValue.data(using: String.Encoding.utf8) else {
                  print("Error saving text to Keychain")
                  return
                }
                
                // Add item to a shared Keychain
                let queryAdd: [String: AnyObject] = [
                  kSecClass as String: kSecClassGenericPassword,
                  kSecAttrAccount as String: itemKey as AnyObject,
                  kSecValueData as String: valueData as AnyObject,
                  kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked,
                  kSecAttrAccessGroup as String: keychainAccessGroupName as AnyObject
                ]
                let resultCode = SecItemAdd(queryAdd as CFDictionary, nil)
                
                // Find a shared Keychain item
                let queryLoad: [String: AnyObject] = [
                  kSecClass as String: kSecClassGenericPassword,
                  kSecAttrAccount as String: itemKey as AnyObject,
                  kSecReturnData as String: kCFBooleanTrue,
                  kSecMatchLimit as String: kSecMatchLimitOne,
                  kSecAttrAccessGroup as String: keychainAccessGroupName as AnyObject
                ]
                
                var result: AnyObject?

                let resultCodeLoad = withUnsafeMutablePointer(to: &result) {
                  SecItemCopyMatching(queryLoad as CFDictionary, UnsafeMutablePointer($0))
                }

                if resultCodeLoad == noErr {
                  if let result = result as? Data,
                    let keyValue = NSString(data: result,
                                            encoding: String.Encoding.utf8.rawValue) as? String {

                    // Found successfully
                    print(keyValue)
                  }
                } else {
                  print("Error loading from Keychain: \(resultCodeLoad)")
                }
                
                // Delete a shared Keychain item
//                let queryDelete: [String: AnyObject] = [
//                  kSecClass as String: kSecClassGenericPassword,
//                  kSecAttrAccount as String: itemKey as AnyObject,
//                  kSecAttrAccessGroup as String: keychainAccessGroupName as AnyObject
//                ]
//                let resultCodeDelete = SecItemDelete(queryDelete as CFDictionary)
//                if resultCodeDelete != noErr {
//                  print("Error deleting from Keychain: \(resultCodeDelete)")
//                }
                
                /// Old code
                guard let jsonTokensString = KeychainWrapper.standard.string(forKey: "tlv_tokens")
                else {
                    
                    guard let ssoToken = KeychainWrapper.standard.string(forKey: "sso_token")
                    else {
                        pageNum = 1 // perform Interactive Login
                        return
                    }
                    
                    // SSO token found. Convert it to OAuth2 tokens
                    let url = "https://tlvsso.azurewebsites.net/api/sso_login"
                    
                    let deviceId = UIDevice.current.identifierForVendor!.uuidString
                    let parameters: [String: String] = [
                        "clientId": clientId,
                        "scope": "openid offline_access https://TlvfpB2CPPR.onmicrosoft.com/\(clientId)/TLV.Digitel.All",
                        "deviceId": deviceId,
                        "ssoToken": ssoToken
                    ]
                    
                    self.isLoading = true
                    
                    AF.request(url, method: .post, parameters: parameters, encoder: JSONParameterEncoder.default)
                        .responseDecodable(of: StrictDecodableTokens.self) { response in
      
                            switch response.result {
                                case .success(let jsonTokens): do {
                                    
                                    self.jsonTokens = DecodableTokens(access_token: jsonTokens.access_token,
                                                                      token_type: jsonTokens.token_type,
                                                                      expires_in: jsonTokens.expires_in,
                                                                      refresh_token: jsonTokens.refresh_token,
                                                                      id_token: jsonTokens.id_token,
                                                                      sso_token: ssoToken)
                                    
                                    let jsonEncoder = JSONEncoder()
                                    let jsonData = try jsonEncoder.encode(jsonTokens)
                                    let jsonString = String(data: jsonData, encoding: String.Encoding.utf8)
                                
                                    KeychainWrapper.standard.set(jsonString!, forKey: "tlv_tokens")
                                    self.isLoading.toggle()
                                    print("isLoading \(isLoading)")
                                    self.pageNum = 3
                                
                                }
                                catch  let error {
                                    print("🥶 \(error)")
                                }
                                
                                case .failure(let error):
                                    print("🥶 \(error)")
                            }
                            
                    }
                    
                    return
                }
        
                // OAuth2 tokens found. Just use them
                let data = jsonTokensString.data(using: .utf8)!
                do {
                    let jsonDecoder = JSONDecoder()
                    self.jsonTokens = try jsonDecoder.decode(DecodableTokens.self, from: data)
                    pageNum = 3
                } catch let error {
                    print("Tokens deserialization error: \(error)")
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

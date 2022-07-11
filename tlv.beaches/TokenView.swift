//
//  TokenView.swift
//  tlv.beaches
//
//  Created by Oleg Kleiman on 10/07/2022.
//

import SwiftUI
import Foundation
import JWTDecode
import Alamofire
import OktaJWT
import SwiftKeychainWrapper

let ISSUER: String =
"https://TlvfpB2CPPR.b2clogin.com/TlvfpB2CPPR.onmicrosoft.com/B2C_1A_B2C_1_ROPC_KIEV_RP/v2.0/"

struct ErrorState: Decodable
{
    let isError: Bool
    let code: Int
    let description: String
}

struct DecodableResponseBeaches : Decodable {
    let codes: String
    let errorState: ErrorState
}

struct TokenView: View {
    
    @Binding var pageNum: Int
    @Binding var jsonTokens: DecodableTokens?
    
    @State private var issuer: String = ""
    @State private var subject: String = ""
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var groups: String = ""
    @State private var expiresAt: Date? = nil
    
    @State private var showVlidationResults = false
    @State private var validationMessage = ""
    
    var body: some View {
        VStack {
            Text("ID Token:")
                .font(.title)
            
            HStack(alignment: .center) {
                Text("name")
                TextField("Name", text: $name)
                    .padding(2)
            }
            .padding(2)
            
            HStack {
                Text("email")
                TextField("EMail", text: $email)
                    .padding(2)
            }

//            TextField("Expires at", text: stringFromDate($expiresAt))
//                .padding(2)
            TextField("Issuer", text: $issuer)
                .padding(2)
                .font(.body)
                .onAppear {
                    if let id_token = jsonTokens?.id_token {
                        let jwt = try? decode(jwt: id_token)
                        self.issuer = jwt?.issuer ?? "unknown"
                        self.subject = jwt?.subject ?? "unknown"
                        self.expiresAt = jwt?.expiresAt ?? nil

                        var claim = jwt?.claim(name: "name")
                        self.name = claim?.string ?? "unknown"

                        claim = jwt?.claim(name: "signInNamesInfo.emailAddress")
                        self.email = claim?.string ?? "unknown"
                    }
                }
            TextField("Subject", text: $subject)
            
            Button {
                Task {
                    
                    let options = [
                      "issuer": ISSUER,
                      "exp": true,
                      "iat": true,
                      "scp": "TLV.Digitel.All"
                    ] as [String: Any]

                    let validator = OktaJWTValidator(options)

                    do {
                        if let accessToken = jsonTokens?.access_token {

                            _ = try validator.isValid(accessToken)
                            validationMessage = "The token is valid"
                            
                        }

                    } catch let error {
                        validationMessage = "Error: \(error)"
                    }

                    showVlidationResults = true

                }
            } label: {
                Text("Validate")
                    .padding(2)
            }
            .alert(isPresented: $showVlidationResults) {
                Alert(title: Text("Validation Results"), message: Text(validationMessage), dismissButton: .default(Text("OK")))
            }
            
            VStack {
                Text("Access Token:")
                    .font(.title)
                
                TextField("Groups", text: $groups)
                    .padding(2)
                    .onAppear {
                        
                        if let access_token = jsonTokens?.access_token {
                        
                            let jwt = try? decode(jwt: access_token)
                            var claim = jwt?.claim(name: "groups")
                            self.groups = claim?.string ?? "unknown"
                        }
                    }
            }
            
            Button {
                self.pageNum = 0
                KeychainWrapper.standard.removeObject(forKey: "tlv_tokens")
            } label: {
                Text("Logout")
            }

            Spacer()
            
            VStack {
                
//                Button("Check Facilities") {
//                    Task {
//                        let url = URL(string: "https://api.tel-aviv.gov.il/tlvbeaches/api/CrmDigitelBeach/GetEligibility")!
//
//                        let parameters: [String: String] = [
//                            "siteID": "0",
//                            "parkID": "0",
//                            "digitelTrack": "313069486"
//                        ]
//
//                        let headers: HTTPHeaders = [
//                            .authorization(bearerToken: jsonTokens!.access_token),
//                        ]
//
//
//                        AF.request(url, method: .post, parameters: parameters, encoder:JSONParameterEncoder.default, headers: headers)
//                            .responseDecodable(of: DecodableResponseBeaches.self) { response in
//                                var res = response.result
//                                print(res)
//                        }
//                    }
//                }
                
                Button("Launch Digitel") {
                    Task {
                        
                        let access_token = jsonTokens?.access_token
                        let deeplinkURL = "tel-aviv://com.digitel/home?access_token=\(access_token!)"
                        
                        let url = URL(string: deeplinkURL)
                        if  UIApplication.shared.canOpenURL(url!) {
                            UIApplication.shared.open(url!) { success in
                                print("Open \(String(describing: url)): \(success)")
                            }
                        }
                    }
                }
            }
        }
    }
    
}

//
//  OTPView.swift
//  tlv.beaches
//
//  Created by Oleg Kleiman on 10/07/2022.
//

import SwiftUI
import Foundation
import Alamofire
import SwiftKeychainWrapper

struct OTPView: View {

    @Binding var pageNum: Int
    @Binding var phoneNumber: String
    @Binding var userId: String
    @Binding var jsonTokens: DecodableTokens?
    @Binding var clientId: String
    
    @State private var otp: String = ""
    @State private var errorMessage: String = ""
    @State private var showError = false
    
    @State private var isLoading = false
    
    var body: some View {
        
        VStack(alignment: .center, spacing: 22) {
            HStack {
                Text("OTP")
                    .textContentType(.oneTimeCode)
                    .padding()
                    .font(.body)
                TextField("Code you've received", text: $otp)
                    .keyboardType(.numberPad)
            }
            .padding()
            
            HStack {
                Button(action: {
                    Task {

                        let url = URL(string: "https://tlvsso.azurewebsites.net/api/login")!
                        
                        let deviceId = UIDevice.current.identifierForVendor!.uuidString
                        let parameters: [String: String] = [
                            "phoneNumber": phoneNumber,
                            "otp": otp,
                            "clientId": clientId,
                            "scope": "openid offline_access https://TlvfpB2CPPR.onmicrosoft.com/\(clientId)/TLV.Digitel.All",
                            "deviceId": deviceId
                        ]

                        self.isLoading = true
                        AF.request(url, method: .post, parameters: parameters, encoder: JSONParameterEncoder.default)
                            .validate(statusCode: 200..<300)
                            .responseDecodable(of: DecodableTokens.self) { response in
                                
                                switch response.result {
                                    
                                    case .success(let jsonTokens):
                                        self.jsonTokens = jsonTokens
                                    
                                        do {
                                            let jsonEncoder = JSONEncoder()
                                            let jsonData = try jsonEncoder.encode(jsonTokens)
                                            let jsonString = String(data: jsonData, encoding: String.Encoding.utf8)
                                        
                                            KeychainWrapper.standard.set(jsonString!, forKey: "tlv_tokens")
                                            KeychainWrapper.standard.set(jsonTokens.sso_token!, forKey: "sso_token")
                                            self.pageNum = 3
                                        } catch  let error {
                                            print("🥶 \(error)")
                                        }
                                    case .failure(let error):
                                        print("🥶 \(error)")
                                }
                                
    //                            if response.response?.statusCode == 200 {
    //                                self.jsonTokens = response.value!
    //                                self.stage = 2
    //                            } else {
    //                                let error = response.result
    //                                print(error)
    //                            }
                                
                                self.isLoading = false
                        }

                    }
                }) {
                    ZStack(alignment: .center) {
                        Circle()
                            .foregroundColor(.pink)
                            .frame(width: 60, height: 60)
                        Image(systemName: "arrow.right")
                            .font(.title)
                            .foregroundColor(.white)
                    }
                }
                .disabled(self.isLoading)
                .padding()
                
                Spacer()
                
                Button("Send again") {
                    self.pageNum = 1
                }
                .disabled(self.isLoading)
                .padding()
                
            }
            .padding(20)
            
            if showError {
                VStack {
                    TextField("", text: $errorMessage)
                        .padding()
                        .foregroundColor(.red)
                    Button {
                        self.pageNum = 0
                    } label: {
                        Text("Try again")
                            .padding(2)
                    }
                }
            }
            
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
            }
            
            Spacer()

        }
    }
}

struct OTPView_Previews: PreviewProvider {

    static var previews: some View {

        OTPView(pageNum: .constant(0), phoneNumber: .constant("0543307026"),
                userId: .constant("31306948"),
                jsonTokens: .constant(sampleTokens),
                clientId: .constant("8739c7f1-e812-4461-b9c8-d670307dd22b")
        )
    }
}

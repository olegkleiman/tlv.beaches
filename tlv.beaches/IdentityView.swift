//
//  IdentityView.swift
//  tlv.beaches
//
//  Created by Oleg Kleiman on 10/07/2022.
//

import SwiftUI
import Foundation
import Alamofire

let lightGreyColor = Color(red: 239.0/255.0, green: 243.0/255.0, blue: 244.0/255.0, opacity: 1.0)

struct SendOTPResponse: Codable {
    let isError: Bool
    let errorDesc: String
    let errorId: Int
}

struct DirectionsText: View {
    var body: some View {
        return Text("Sign in to your account with Citizen ID and Mobile Phone Number")
            .font(.title3)
            .fontWeight(.light)
            .padding(EdgeInsets(top: 20, leading: 0,
                                bottom: 60, trailing: 0))
    }
}

struct IdentityView: View {
    
    @Binding var pageNum: Int
    @Binding var phoneNumber: String
    @Binding var userId: String
    
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage: String = ""
    
    var body: some View {
        VStack(alignment: .center, spacing: 22) {

            VStack {
                
                DirectionsText()
                
                Label {
                    ZStack(alignment: .leading) {
                        if userId.isEmpty {
                            Text("Citizen Id")
                                .foregroundColor(.gray)
                        }
                        TextField("", text: $userId)
                            .cornerRadius(5.0)
                            .keyboardType(.numberPad)
                    }.padding()
                } icon: {
                    Image(systemName: "person")
                        .frame(width: 24, height: 24)
                        .foregroundColor(.blue)
                        .padding(.leading)
                }
                
                Divider()
                    .background(.gray)
                
                Label {
                    ZStack(alignment: .leading) {
                        if phoneNumber.isEmpty {
                            Text("Phone Number")
                                .foregroundColor(.gray)
                        }
                        TextField("", text: $phoneNumber)
                            .cornerRadius(5.0)
                            .keyboardType(.numberPad)
                    }.padding()
                } icon: {
                        Image(systemName: "phone")
                            .frame(width: 24, height: 24)
                            .foregroundColor(.blue)
                            .padding(.leading)
                }
                Divider()
                    .background(.gray)
                
                Spacer()
                
                ZStack(alignment: .leading) {
                    
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .padding()
                        .opacity(isLoading ? 1 : 0)
                    
                    Button(action: {
                        Task {
                            
                            self.isLoading = true
                            
                            let url = URL(string:"https://tlvsso.azurewebsites.net/api/request_otp")!
                            
                            let parameters: [String: String] = [
                                "userId": userId,
                                "phoneNumber": phoneNumber
                            ]
                            
                            AF.request(url, method: .post, parameters: parameters, encoder: JSONParameterEncoder.default)
                                .responseDecodable(of: SendOTPResponse.self) { response in
                                    if !response.value!.isError as Bool {
                                        self.pageNum = 1
                                    } else
                                    {
                                        self.errorMessage = (response.value?.errorDesc as? String)!
                                        self.showError = true
                                    }
                                    
                                    self.isLoading.toggle()
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
                        .padding(.top,35)
                    }
//                    .disabled(self.isLoading)
                    .opacity(!isLoading ? 1 : 0)
                }
                
                if showError {
                    VStack {
                        TextField("", text: $errorMessage)
                            .padding()
                            .foregroundColor(.red)
                    }
                }
            }
            
//            if isLoading {
//                ProgressView()
//                    .progressViewStyle(CircularProgressViewStyle())
//            }
            
            Spacer()
            
        }
        .padding()

    }
    
}

struct IdentityView_Previews: PreviewProvider {

    static var previews: some View {

        IdentityView(pageNum: .constant(0), phoneNumber: .constant("0543307026"), userId: .constant("31306948"))
    }
}


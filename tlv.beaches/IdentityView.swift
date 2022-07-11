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

struct WelcomeText: View {
    var body: some View {
        return Text("Welcome")
            .font(.title2)
            .fontWeight(.semibold)
            .padding(.top, 20)
    }
}

struct DirectionsText: View {
    var body: some View {
        return Text("Sign in to your account with Citizen ID and Mobile Phone Number")
            .font(.title3)
            .fontWeight(.light)
            .padding(.top, 20)
            .padding(.leading, 20)
            .padding(.trailing, 20)
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
                
                WelcomeText()
                DirectionsText()
                
                HStack {
                    TextField("Citizen Id", text: $userId)
                        .background(lightGreyColor)
                        .cornerRadius(5.0)
                        .keyboardType(.numberPad)
                }.padding()
                HStack {
                    TextField("Phone Number", text: $phoneNumber)
                        .background(lightGreyColor)
                        .cornerRadius(5.0)
                        .keyboardType(.numberPad)
                        
                }.padding()
                Button {
                    Task {
                        
                        let url = URL(string:"https://tlvsso.azurewebsites.net/api/request_otp")!
                        
                        let parameters: [String: String] = [
                            "userId": userId,
                            "phoneNumber": phoneNumber
                        ]
                        
                        self.isLoading = true
                        AF.request(url, method: .post, parameters: parameters, encoder: JSONParameterEncoder.default)
                            .responseDecodable(of: SendOTPResponse.self) { response in
                                if !response.value!.isError as Bool {
                                    self.pageNum = 1
                                } else
                                {
                                    self.errorMessage = (response.value?.errorDesc as? String)!
                                    self.showError = true
                                }
                        }

                    }

                } label: {
                    Text("Continue")
                            .padding(2)
                }
                .disabled(self.isLoading)
                
                if showError {
                    VStack {
                        TextField("", text: $errorMessage)
                            .padding()
                            .foregroundColor(.red)
                    }
                }
            }
            
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
            }
            
            Spacer()
            
        }
        .padding()

    }
    
}

//struct IdentityView_Previews: PreviewProvider {
//
//    @Binding var pageNumber: Int
//    @Binding var phoneNumber: String = "0543307026"
//    @Binding var userId: String = "31306948"
//
//    static var previews: some View {
//
//        IdentityView(pageNum: $pageNumber, phoneNumber: $phoneNumber, userId: $userId)
//    }
//}


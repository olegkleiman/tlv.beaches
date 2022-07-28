//
//  GuestView.swift
//  tlv.beaches
//
//  Created by Oleg Kleiman on 13/07/2022.
//

import SwiftUI
import Alamofire

struct GuestDirectionsText: View {
    var body: some View {
        return Text("One-time login")
            .font(.title3)
            .fontWeight(.light)
            .padding(EdgeInsets(top: 20, leading: 0,
                                bottom: 60, trailing: 0))
    }
}

struct GuestView: View {
    
    @Binding var userName: String
    @Binding var phoneNumber: String
    @Binding var email: String
    
    @State private var isLoading = false
    
    var body: some View {
        VStack(alignment: .center, spacing: 22) {
            
            VStack {
                
                GuestDirectionsText()
                
                Label {
                    ZStack(alignment: .leading) {
                        if userName.isEmpty {
                            Text("Full Name")
                                .foregroundColor(.gray)
                        }
                        TextField("", text: $userName)
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
                
                Label {
                    ZStack(alignment: .leading) {
                        if email.isEmpty {
                            Text("Phone Number")
                                .foregroundColor(.gray)
                        }
                        TextField("", text: $email)
                            .cornerRadius(5.0)
                            .keyboardType(.numberPad)
                    }.padding()
                } icon: {
                        Image(systemName: "mail")
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
                                "userName": userName,
                                "phoneNumber": phoneNumber,
                                "email": email
                            ]
                            
                            AF.request(url, method: .post, parameters: parameters, encoder: JSONParameterEncoder.default)
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
                    .opacity(!isLoading ? 1 : 0)
                }
            }
        }
    }
}

struct GuestView_Previews: PreviewProvider {
    static var previews: some View {
        GuestView(userName: .constant("Oleg Kleiman"),
                  phoneNumber: .constant("0543307026"),
                  email: .constant("oleg_kleyman@yahoo.com"))
    }
}

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
                .foregroundColor(.pink)
            
            VStack {
                Divider().background(.gray)
                
                HStack {
                    Text("Name:")
                        .font(.system(size: 16, weight: .heavy))
                    Text(name)
                    Spacer()
                    
                }
                .padding()

                Divider().background(.gray)
            }

            
            VStack {
                HStack(alignment: .center) {
                    Text("Email:")
                        .font(.system(size: 16, weight: .heavy))
                    Text(email)
                    Spacer()
                }
                .padding()
                
                Divider().background(.gray)
            }

//            TextField("Expires at", text: stringFromDate($expiresAt))
//                .padding(2)
            VStack {
                HStack {
                    Text("Issuer:")
                        .font(.system(size: 16, weight: .heavy))
                    Text(issuer)
                        .truncationMode(.tail)
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
                    
                }
                .padding()
                
                Divider().background(.gray)
            }
            
            VStack {
                HStack {
                    Text("Subject:")
                        .font(.system(size: 16, weight: .heavy))
                    Text(subject)
                        .truncationMode(.tail)
                    Spacer()
                }
                .padding()
                
                Divider().background(.gray)
            }
            
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
                    .foregroundColor(.pink)
                
                HStack {
                    Text("Groups")
                        .font(.system(size: 16, weight: .heavy))
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
                .padding()
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

struct TokenPreviews: PreviewProvider {
    static var previews: some View {
        TokenView(pageNum: .constant(2),
                  jsonTokens: .constant(DecodableTokens(
                    access_token: "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsImtpZCI6IlRqSGtSaDFxXzBTWXBJUjZhTmE4ZldUWHBWSW9wNWl3SjhQUmc5YjRrNUEifQ.eyJpc3MiOiJodHRwczovL3RsdmZwYjJjcHByLmIyY2xvZ2luLmNvbS83ODFlYzI0ZC05YWE1LTQ2MjgtOWZjMS01YTFmMTNkYzA0MjQvdjIuMC8iLCJleHAiOjE2NTc1ODMzOTcsIm5iZiI6MTY1NzU3OTc5NiwiYXVkIjoiODczOWM3ZjEtZTgxMi00NDYxLWI5YzgtZDY3MDMwN2RkMjJiIiwic3ViIjoiYTBkYzQ5YmEtZDI5Ny00M2E1LTkzYWQtZjM1MTJlMjQ4MTdiIiwic2lnbkluTmFtZXMucGhvbmVOdW1iZXIiOiIwNTQzMzA3MDI2Iiwic2lnbkluTmFtZXMuY2l0aXplbklkIjoiMzEzMDY5NDg2IiwidXBuIjoiYTBkYzQ5YmEtZDI5Ny00M2E1LTkzYWQtZjM1MTJlMjQ4MTdiQFRsdmZwQjJDUFBSLm9ubWljcm9zb2Z0LmNvbSIsIm5hbWUiOiJPbGVnIEtsZWltYW4iLCJzaWduSW5OYW1lc0luZm8uZW1haWxBZGRyZXNzIjoib2xlZ19rbGV5bWFuQHlhaG9vLmNvbSIsImZhbWlseV9uYW1lIjoiS2xlaW1hbiIsImdyb3VwcyI6IltEaWdpdGVsIE1lbWJlcnNdIiwic2NwIjoiVExWLkRpZ2l0ZWwuQWxsIiwiYXpwIjoiODczOWM3ZjEtZTgxMi00NDYxLWI5YzgtZDY3MDMwN2RkMjJiIiwidmVyIjoiMS4wIiwiaWF0IjoxNjU3NTc5Nzk2fQ.xPN_j4nT2RRPedAOsvyLkty-K-zl96BVedE6ORNZl6X136WhKOjfZTdDV5ICYMAw_p2nfX2XOm8BI4e6VTfCK7gH84u2s6tlu4T_zCOf-so9OkWXd-bYpHSM-m1pJ_gzCo04sXYNWn8AWXUzZE_UFiH29YacXQUH6tR-kyqnIfpqOes-yALwRWczbN-x1j4E_GLhY90H--KNVxdnpZCkaGkbUgst921PlTEmUZuszD_hQMgI4cbVk0rvncJmdMAJ80P_2ZVzEFWc05pKkJXSlHSFAronSm6RZb4KBAW4DKEScaAHSTAckS4qCRCHHrJ1Sf9lVeQXJ_mPTabALsJ6uQ",
                    token_type: "Bearer",
                    expires_in: "3601",
                    refresh_token: "eyJraWQiOiJDOHVoR3dQUGxXV2xIaUY3eUZHQkJhREpuQS1WR0didEU0SFlIaFlfQ0ZVIiwidmVyIjoiMS4wIiwiemlwIjoiRGVmbGF0ZSIsInNlciI6IjEuMCJ9.fgytAzVsYpprdWMfa8WYgKB92lTVkqjz7Qxwioo1vCtVIBMIpQG6lA4cJjmnynv89EZeIyqWXx_tn1fFHAB01Gc8WgkgxUgMaWRoO1ciOPsItqwZLAUGc66-vSbw_sGMcIq2S_qlK32S7HzSuLC-jB8LwSsm-fBCuWc69psIzG2WjScpunikHy6JV42SKMCmM4js8UmzsBJoS60MECLEjwWcqeOyCpkrf07tox_Lp4Y-ZVLeCeTTXy_-kDm6TWHEFplS0wxrU3P4H2H9VLIsgdViezVnNSDi5cHXYxL2Akndwa7lMSiNz3cNB6AEEBQhFsglK7vqrHNBHi8rWicskw._yalRa6PddSx2uqG.GyK3wAipc9XMwFNnijBBOFIv5QEUwbkGjtfGUna-8e_Py87CgWy8stTrvNXeKFnO0VRaAguE9pn119wkSwucPrBw098O9nFwqDBNFnCchYduwEeESz7_JzsjVfVTyJqls1OE4OBOkcyBU-n4my-DcuLj8tCHD9FwrR7e_15DxHJUNwBhZSr7KH0GnV1ozV6zXqGviBqIPldURndq1gsM-7IC-VQzkT0lGKcLMuTYa-lnmaivU589W30Q7YO9vsOVcTOed_tP1PlredoFQg6VvUQYDb2_g1x-PKKpEUybo4VnEmXOsFAaRUB3jjAG5X6Ugj1Dh4GTLK_RRpoMhGUZzXyDrsLqbDhf9Z7oYK8Y1T9aNrd14tTZhHZukHl7IqzksuwKMLYApIfMxiCkgiwBb5IPZLwv82ZBHQKxuTuDLOqH61MnJrgLFN95Crjo7pukyx9YOHWcLZt4VKhNC2f_OlNgR1jYoWVqVfSYjeBI5mBrdF59hQLB--QqivrDSUv8UXNEjsE-gvymFaSTxfuS5miCdrrOSPbQOM9h7_NEgQVaK2rcxyEMv5SxtP1ifRJ_qRQx0WhDCuRWwXkE_XT8BJpwIhLo23qjKpvnTo8tk2ysjiIDJ_YT03MuHKaNw6cem-sZ0Zo26e7p3POxwvutxXhnTk7rm3ZtZGdHKGJ7Avpjbh-GH1MguFY-GrP9qtDdEiM4_0iC7oaYuGuxjaCoNtSKJTr3gBP7symPPnjyN82WE3Zjp8TtdL1b8f-a8e1lmNepQpR1JGV5qnAW7BaICXN-8ng93vqxS36nLfBDH-3vhY6cDJ8fEIYa1SRtGAWRHAP-AeVXXmexQhu8zMQ.6O8eUIDyirLAW_PriRqCvg",
                    id_token: "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsImtpZCI6IlRqSGtSaDFxXzBTWXBJUjZhTmE4ZldUWHBWSW9wNWl3SjhQUmc5YjRrNUEifQ.eyJleHAiOjE2NTc1ODMzOTgsIm5iZiI6MTY1NzU3OTc5NywidmVyIjoiMS4wIiwiaXNzIjoiaHR0cHM6Ly90bHZmcGIyY3Bwci5iMmNsb2dpbi5jb20vNzgxZWMyNGQtOWFhNS00NjI4LTlmYzEtNWExZjEzZGMwNDI0L3YyLjAvIiwic3ViIjoiYTBkYzQ5YmEtZDI5Ny00M2E1LTkzYWQtZjM1MTJlMjQ4MTdiIiwiYXVkIjoiODczOWM3ZjEtZTgxMi00NDYxLWI5YzgtZDY3MDMwN2RkMjJiIiwiYWNyIjoiYjJjXzFhX2IyY18xX3JvcGNfa2lldl9ycCIsImlhdCI6MTY1NzU3OTc5NywiYXV0aF90aW1lIjoxNjU3NTc5Nzk3LCJzaWduSW5OYW1lcy5waG9uZU51bWJlciI6IjA1NDMzMDcwMjYiLCJzaWduSW5OYW1lcy5jaXRpemVuSWQiOiIzMTMwNjk0ODYiLCJ1cG4iOiJhMGRjNDliYS1kMjk3LTQzYTUtOTNhZC1mMzUxMmUyNDgxN2JAVGx2ZnBCMkNQUFIub25taWNyb3NvZnQuY29tIiwibmFtZSI6Ik9sZWcgS2xlaW1hbiIsInNpZ25Jbk5hbWVzSW5mby5lbWFpbEFkZHJlc3MiOiJvbGVnX2tsZXltYW5AeWFob28uY29tIiwiZmFtaWx5X25hbWUiOiJLbGVpbWFuIiwiZ3JvdXBzIjoiW0RpZ2l0ZWwgTWVtYmVyc10iLCJhdF9oYXNoIjoiRGc1MUlCanAtbkhGd1NTeU9rZDhSQSJ9.rmyv5oIjqM_qpWSC2EzQLqJeTwFav8KFtpT8GYEL_tX58KVDqTYHCE0Fpzg5BJQWMwlWP3CwKuW_ub-KLMbEaPz-KpijMDYH_KD25vNpnWegKPSjnyiL2G4gAlvbLDLVfe5ralRpvdbD2zSl8UP9S6I-O1Zxf3sTgykqXFGRHCGX3XuWtDCH4_JBeQdveVRqrt1duWTZaiCcvcjRu3kCqyiibDUeVII8DugXTWnFtvoDj03wo-STZWDg-9MKjuNzdft0Q5DALi8H0Fr0gWtsQ98sUlJkdihkHHsx50k_cq3q_dRA7tGUPexAwF7AIBjY7IlNDZXN712DCAGZ9g7Cag")
            ))
    }
}



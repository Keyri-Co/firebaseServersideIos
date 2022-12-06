//
//  Network.swift
//  FirebaseKeyriServerside
//
//  Created by Aditya Malladi on 12/4/22.
//

import Foundation
import FirebaseAuth
import keyri_pod
import CryptoKit

public class Network {
    public static func registerUser(from username: String) {
        let keyri = Keyri()
        let publicKey: P256.Signing.PublicKey?


        publicKey = try! keyri.generateAssociationKey(username: username)
   
        
        let body = "{\"email\": \"\(username)\",\"publicKey\": \"\(publicKey!.derRepresentation.base64EncodedString())\"}"
        print(body)


        var req = URLRequest(url: URL(string: "https://keyri-firebase-serverside-authentication.vercel.app/api/keyriregistration")!)
        req.httpMethod = "POST"

        req.httpBody = body.data(using: .utf8)!
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        req.addValue("*/*", forHTTPHeaderField: "Accept")
        req.addValue("gzip, deflate, br", forHTTPHeaderField: "Accept-Encoding")
        req.addValue("keep-alive", forHTTPHeaderField: "Connection")

        URLSession.shared.dataTask(with: req) { data, res, err in
            if let res = res {
                print(res)
            }
            
            if let data = data {
                print(data)
                print(String(data: data, encoding: .utf8)!)
                
                let token = String(data: data, encoding: .utf8)!
                
                Auth.auth().signIn(withCustomToken: token) { result, error in
                    if let result = result {
                        print(result.user.email)
                        print(result.user.displayName)
                    }
                }
            }
            
            if let err = err {
                print(err)
            }
            
        }.resume()
    }
    
    
    
    public static func loginUser(username: String, completion: @escaping (() -> ())) {
        print(username)
        let keyri = Keyri()
        let publicKey: P256.Signing.PublicKey?
        if let key = try! keyri.getAssociationKey(username: username) {
            print("Found login")
            publicKey = key
        }
        
        do {
            guard let loginBody = self.generateTSNonce(username: username) else { return }
            var req = URLRequest(url: URL(string: "https://keyri-firebase-serverside-authentication.vercel.app/api/keyrilogin")!)
            req.httpMethod = "POST"
            
            print(loginBody)
            req.httpBody = loginBody.data(using: .utf8)!
            req.addValue("application/json", forHTTPHeaderField: "Content-Type")
            req.addValue("*/*", forHTTPHeaderField: "Accept")
            req.addValue("gzip, deflate, br", forHTTPHeaderField: "Accept-Encoding")
            req.addValue("keep-alive", forHTTPHeaderField: "Connection")
            
            
            URLSession.shared.dataTask(with: req) { data, res, err in
                if let res = res {
                    print(res)
                }
                
                if let data = data {
                    print(data)
                    let token = String(data: data, encoding: .utf8)!
                    Auth.auth().signIn(withCustomToken: token) { user, error in
                        if let user = user {
                            print(user.user.email)
                            completion()
                        }
                    }
                    
                    
                }
                
                if let err = err {
                    print(err)
                    completion()
                }
                
            }.resume()
            
        } catch {
            print(error)
        }
        

    }
    
    public static func QRAuth(username: String) {
        print(username)
        let keyri = Keyri()
        let publicKey: P256.Signing.PublicKey?
        if let key = try! keyri.getAssociationKey(username: username) {
            print("Found login")
            publicKey = key
        }

        guard let loginBody = self.generateTSNonce(username: username) else { return }
        
        DispatchQueue.main.async {
            keyri.easyKeyriAuth(publicUserId: "", appKey: "WEK6J987IRXbg7IJbLzF6tuTZIVKcnqc", payload: loginBody) {
                res in
                print(res)
            }
        }
    }
    
    
    private static func generateTSNonce(username: String) -> String? {
        let split = String(Date().timeIntervalSince1970).split(separator: ".")
        let ts = split[0] + split[1]
        let nonce = String(Int.random(in: 0...99999999))
        let ts_nonce = ts + "_" + nonce
        
        do {
            let signature = try Keyri().generateUserSignature(for: username, data: ts_nonce.data(using: .utf8)!)
            return "{\"email\": \"\(username)\",\"data\": \"\(ts_nonce)\",\"signature\": \"\(signature.derRepresentation.base64EncodedString())\"}"
        } catch {
            return nil
        }
    }
}

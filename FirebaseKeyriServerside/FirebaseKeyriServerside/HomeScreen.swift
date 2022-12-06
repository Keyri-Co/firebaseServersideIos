//
//  ContentView.swift
//  FirebaseKeyriServerside
//
//  Created by Aditya Malladi on 12/3/22.
//

import SwiftUI
import FirebaseAuth
import LocalAuthentication
import keyri_pod

struct HomeScreen: View {
    @State var presentingModal = false
    @State private var usernamePW: String = ""
    @State private var pw: String = ""
    @State private var usernameNOPW: String = ""
    
    
    var body: some View {
        VStack {
            ZStack {
                Color.white
                VStack {
                    Text("Password Auth").foregroundColor(Color.green)
                    TextField(
                        "email",
                        text: $usernamePW
                    ).border(.secondary)
                        .padding(.leading, 20)
                        .padding(.trailing, 20)
                    SecureField(
                        "Password",
                        text: $pw
                    ).border(.secondary)
                        .padding(.leading, 20)
                        .padding(.trailing, 20)
                    Button("Login"){
                        Auth.auth().signIn(withEmail: usernamePW, password: pw) { user, error in
                            if let user = user {
                                print(user.user.email)
                                self.presentingModal = true
                            }
                            
                            if let error = error {
                                print(error)
                            }
                            
                        }
                    }.sheet(isPresented: $presentingModal) {         ModalView(presentedAsModal: self.$presentingModal, username: $usernamePW) }
                    Button("Register") {
                        Auth.auth().createUser(withEmail: usernamePW, password: pw) {user, error in
                            if let user = user {
                                try! Keyri().generateAssociationKey(username: usernamePW)
                                print(user.user.email)
                                self.presentingModal = true
                            }
                            
                            if let error = error {
                                print(error)
                            }
                            
                        }
                    }.sheet(isPresented: $presentingModal) {
                        ModalView(presentedAsModal: self.$presentingModal, username: $usernamePW)
                    }
                }
            }
            
            ZStack {
                Color.white
                VStack {
                    Text("Passwordless Auth").foregroundColor(Color.red)
                    TextField(
                        "email",
                        text: $usernameNOPW
                    ).border(.secondary)
                        .padding(.leading, 20)
                        .padding(.trailing, 20)
                    Button("Login"){
                        print("HELLO")
                        print(usernameNOPW)
                        let context = LAContext()
                        var error: NSError?

                        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
                            let reason = "Identify yourself"

                            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) {
                                success, authenticationError in

                                DispatchQueue.main.async {
                                    if success {
                                        Network.loginUser(username: usernameNOPW) {
                                            self.presentingModal = true
                                        }
                                    } else {
                                        // error
                                    }
                                }
                            }
                        }
                    }.sheet(isPresented: $presentingModal) {
                        ModalView(presentedAsModal: self.$presentingModal, username: $usernameNOPW)
                    }
                    Button("Register") {
                        let context = LAContext()
                        var error: NSError?

                        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
                            let reason = "Identify yourself"
                            
                            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) {
                                success, authenticationError in
                                
                                DispatchQueue.main.async {
                                    if success {
                                        Network.registerUser(from: usernameNOPW)
                                    } else {
                                        // error
                                    }
                                }
                            }
                        }
                    }
                }
                
            }
        }
    }
}

struct HomeScreen_Previews: PreviewProvider {
    static var previews: some View {
        HomeScreen()
    }
}

struct ModalView: View {
    @Binding var presentedAsModal: Bool
    
    @Binding var username: String
    
    var body: some View {
        ZStack {
            Color.green
            VStack {
                Text("logged in as \(username)")
                Button("sign out") { self.presentedAsModal = false }
            }
        }
    }
}

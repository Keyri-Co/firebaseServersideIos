# firebaseServersideIos

# Mobile (iOS)

As above, we are excluding the code for implementing traditional Firebase authentication methods like email/password, and they are already sufficiently documented by Firebase. **The following section focuses on Keyri passwordless functionality - both for authentication within your app and on your web app via QR login.**

## Install Keyri and Firebase SDKs

```none
  # Pods for KeyriFirebase
  pod 'keyri-pod'
  pod 'FirebaseAuth'
```

Import the following Cocoapods (also available via SPM)

To set up Firebase, follow their setup guide on their developer portal, then download the generated GoogleService-Info.plist file and place it at the root of your project (details on how to get this in the "Get Firebase Client Credentials" section above.

Then, simply import Keyri and Firebase in the files you intend to use them

## Register a Passwordless User

To register a user, one first must set up a keypair with the Keyri SDK and send it to their custom server (details on how to implement that portion in the Server section above). The web server responds with a custom token, which the mobile app uses to get a user from the Firebase SDK using the custom auth method. The code snippet below shows how one can accomplish this easily:&#x20;

Note: We force unwrap in several places for brevity, please be careful with that in production code

```swift
    static func register(username: String) {
        let key = try! Keyri().generateAssociationKey(username: username).derRepresentation.base64EncodedString
        
        let body = "{\"email\": \"\(username)\",\"publicKey\": \"\(String(describing: key))\"}"
        
        var httpReq = URLRequest(url: URL(string: "url.tld/keyriregister")!)
        httpReq.httpBody = body.data(using: .utf8)!
        
        URLSession.shared.dataTask(with: httpReq) { data, _, _ in
            if let data = data {
                let token = String(data: data, encoding: .utf8)!
                Auth.auth().signIn(withCustomToken: token) { user, error in
                    if let user = user {
                        // Log in the user
                    }
                    
                }
            }
            
        }.resume()
```

## Sign in an Existing User In-App

To sign in an existing user, the flow is actually very similar to the registration piece, just with one alteration: the body sent to the custom API (and the endpoint of course). After that, one takes the response from the API (a custom token) and authenticates the same as above. The format of the custom token is&#x20;

```json
{
  "email": "abc@xyz.tld",
  "data": "[utf-8 encoded ${timestamp_nonce} string]",
  "signature": "[base64-encoded ECDH signature]"
}
```

One can use the Keyri SDK to generate this payload, first by looking up the user in Keyri's sdk, and using the key to sign the data (there is a function built into Keyri that does this for you). We display this below

```swift
    static func signIn(username: String) {
        let keyri = Keyri()
        
        if let key = try! keyri.getAssociationKey(username: username) {
            let data =  String(Date.now()) + "_" + String(RandomNumberGenerator().random(100000))
            let signature = try! keyri.generateUserSignature(data: data)
            let payload = "{\"username\": \(username),\"data\": \(data),\"signature\": \"\(signature)\"}"
        }
    }
```

This payload can then be sent to the custom API, which will respond with a Custom Token, which can be used to authenticate the user as shown above.&#x20;

## Sign in an Existing User on Web App via QR Login

Alternatively, one can send the same payload to a browser session via Keyri's QR Auth functionality, using the easyKeyriAuth function:

```swift
Keyri().easyKeyriAuth(username: username, appKey: appKey, payload: payload)
```

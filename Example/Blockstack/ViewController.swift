//
//  ViewController.swift
//  Blockstack
//
//  Created by Yukan Liao on 03/27/2018.
//

import UIKit
import Blockstack
import SafariServices

fileprivate let filename = "testFile"

class ViewController: UIViewController {

    @IBOutlet var nameLabel: UILabel!
    @IBOutlet weak var optionsContainerView: UIScrollView!
    @IBOutlet weak var resetKeychainButton: UIButton!
    @IBOutlet var signInButton: UIButton!

    override func viewDidLoad() {
        self.updateUI()
        Blockstack.shared.isBetaBrowserEnabled = true
    }
    
    @IBAction func signIn() {
        // Address of deployed example web app
        Blockstack.shared.signIn(redirectURI: URL(string: "https://pedantic-mahavira-f15d04.netlify.com/redirect.html")!,
                                 appDomain: URL(string: "https://pedantic-mahavira-f15d04.netlify.com")!, scopes: [.storeWrite, .publishData]) { authResult in
            switch authResult {
                case .success(let userData):
                    print("sign in success")
                    self.handleSignInSuccess(userData: userData)
                case .cancelled:
                    print("sign in cancelled")
                case .failed(let error):
                    print("sign in failed, error: ", error ?? "n/a")
            }
        }
    }
    
    func handleSignInSuccess(userData: UserData) {
        print(userData.profile?.name as Any)
        
        self.updateUI()
        
        // Check if signed in
        // checkIfSignedIn()
    }
    
    @IBAction func signOut(_ sender: Any) {
        // Sign user out
        Blockstack.shared.signUserOut()
        self.updateUI()
    }
    
    @IBAction func resetDeviceKeychain(_ sender: Any) {
        Blockstack.shared.promptClearDeviceKeychain()
    }
    
    @IBAction func putFileTapped(_ sender: Any) {
//        guard self.saveInvalidGaiaConfig() else {
//            return
//        }
        // Put file example
        let alert = UIAlertController(title: "Put File", message: "Type a message to put in the file:", preferredStyle: .alert)
        alert.addTextField { field in
            field.placeholder = "Hello world!"
        }
        self.present(alert, animated: true, completion: nil)
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Send", style: .default) { _ in
            let text: String = alert.textFields?.first?.text ?? "Default Text"
            Blockstack.shared.putFile(to: filename, text: text, sign: true, signingKey: nil) { (publicURL, error) in
                if error != nil {
                    print("put file error")
                } else {
                    print("put file success \(publicURL ?? "NA")")
                }
            }
        })
    }
    
    @IBAction func getFileTapped(_ sender: Any) {                
        // Read data from Gaia
        Blockstack.shared.getFile(at: filename, verify: true) { response, error in
            var text: String?
            if error != nil {
                print("get file error")
                text = "Could not get file. Try putting something first!"
            } else {
                print("get file success")
                text = (response as? DecryptedValue)?.plainText ?? "Invalid content"
            }
            let alert = UIAlertController(title: "Get File", message: text, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Done", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    @IBAction func multiplayerGetFileTapped(_ sender: Any) {
        let alert = UIAlertController(title: "Multiplayer Get File", message: "What is the Blockstack ID of the other user?\n\nNote: this will only work if the other user has PUT the file using this sample app.", preferredStyle: .alert)
        alert.addTextField {
            $0.placeholder = "i.e. testuser.id"
        }
        alert.addAction(UIAlertAction(title: "Confirm", style: .default) { _ in
            guard let userID = alert.textFields?.first?.text else {
                let errorAlert = UIAlertController(title: "Oops!", message: "You must enter a valid ID.", preferredStyle: .alert)
                errorAlert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                self.present(errorAlert, animated: true)
                return
            }
            // Read data from Gaia
            Blockstack.shared.getFile(at: filename, username: userID) { response, error in
                if error != nil {
                    print("get file error")
                } else {
                    print("get file success")
                    print(response as Any)
                    let text = response as? String ?? "Oops--something went wrong."
                    let errorAlert = UIAlertController(title: "Get File Result", message: text, preferredStyle: .alert)
                    errorAlert.addAction(UIAlertAction(title: "Done", style: .cancel, handler: nil))
                    self.present(errorAlert, animated: true)
                }
            }
        })
        self.present(alert, animated: true)
    }
    
    @IBAction func deleteFile(_ sender: Any) {
        Blockstack.shared.deleteFile(at: filename, wasSigned: false) { error in
            var message: String?
            if let gaiaError = error as? GaiaError {
                switch gaiaError {
                case .fileNotFoundError:
                    message = "'\(filename)' was not found."
                default:
                    message = "Something went wrong, could not delete file."
                }
            } else {
                message = "Success! '\(filename)' was deleted."
            }
            let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }

    @IBAction func listFiles(_ sender: Any) {
        let sheet = UIAlertController(title: "List Files", message: "List all of your files in this application's Gaia storage bucket?", preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: "Yes", style: .default) { _ in
            var files = [String]()
            Blockstack.shared.listFiles(callback: {
                // Continue until there are no more files
                files.append($0)
                return true
            }, completion: { fileCount, error in
                var message = "\(fileCount) files.\n"
                for i in 0..<fileCount {
                    if i < 50 {
                        message += "\n\(files[i])"
                    } else {
                        message += "\n...and \(fileCount - i + 1) more!"
                        break
                    }
                }
                let alert = UIAlertController(title: "List Files", message: message, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                self.present(alert, animated: true, completion: nil)
            })
        })
        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(sheet, animated: true, completion: nil)
    }

    // MARK: - Private
    
    private func saveInvalidGaiaConfig() -> Bool {
        // Ensure existing hub connection
//        Blockstack.shared.putFile(to: "test", text: "hello") { _, _ in
//        }

        // Get previous gaia config
        guard let data = UserDefaults.standard.value(forKey:
            BlockstackConstants.GaiaHubConfigUserDefaultLabel) as? Data,
            let config = try? PropertyListDecoder().decode(GaiaConfig.self, from: data) else {
                return false
        }
        
        // Create invalid config
        let invalidConfig = GaiaConfig(URLPrefix: config.URLPrefix, address: config.address, token: "v1:invalidated", server: config.server)
        
        // Save invalid gaia config
        Blockstack.shared.clearGaiaSession()
        guard let encodedInvalidConfig = try? PropertyListEncoder().encode(invalidConfig) else {
            return false
        }
        UserDefaults.standard.set(encodedInvalidConfig, forKey: BlockstackConstants.GaiaHubConfigUserDefaultLabel)
        return true
    }
    
    private func updateUI() {
        DispatchQueue.main.async {
            if Blockstack.shared.isUserSignedIn() {
                // Read user profile data
                let retrievedUserData = Blockstack.shared.loadUserData()
                print(retrievedUserData?.profile?.name as Any)
                self.nameLabel.text =
                    retrievedUserData?.profile?.name ?? "Nameless User"
                self.optionsContainerView.isHidden = false
                self.signInButton.isHidden = true
                self.resetKeychainButton.isHidden = true
            } else {
                self.optionsContainerView.isHidden = true
                self.signInButton.isHidden = false
                self.resetKeychainButton.isHidden = false
            }
        }
    }
    
    private func checkIfSignedIn() {
        Blockstack.shared.isUserSignedIn() ? print("currently signed in") : print("not signed in")
    }
}


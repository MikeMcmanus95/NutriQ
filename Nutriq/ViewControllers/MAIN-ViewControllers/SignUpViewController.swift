//
//  SignUpViewController.swift
//  Nutriq
//
//  Created by Michael Mcmanus on 4/12/19.
//  Copyright © 2019 NutriQ. All rights reserved.
//

import UIKit
import Firebase
import GoogleSignIn

class SignUpViewController: UIViewController, GIDSignInDelegate, GIDSignInUIDelegate {

    
    // MARK: - Properties
    
    var username = ""
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var confirmPasswordField: UITextField!
    @IBOutlet weak var emailSignupButtonView: UIView!
    @IBOutlet weak var emailSignupLabel: UILabel!
    @IBOutlet weak var googleSignupButtonView: UIView!
    @IBOutlet weak var googleSignupLabel: UILabel!
    @IBOutlet weak var googleSigninButton: GIDSignInButton!
    
    
    // MARK: - Init
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Customize email signup button
        emailSignupButtonView.layer.cornerRadius = 5
        emailSignupButtonView.layer.masksToBounds = true
        emailSignupLabel.font = UIFont(name: "Roboto-Bold", size: 14)
        emailSignupButtonView.layer.shadowColor = UIColor.black.cgColor
        emailSignupButtonView.layer.shadowOffset = CGSize(width: 5, height: 5)
        emailSignupButtonView.layer.shadowRadius = 5
        emailSignupButtonView.layer.shadowOpacity = 1.0
        
        // Customize Google signup button
        googleSignupButtonView.layer.cornerRadius = 5
        googleSignupButtonView.layer.masksToBounds = true
        googleSignupLabel.font = UIFont(name: "Roboto-Bold", size: 14)
        
        
        // Set the UI delegate of the GIDSignIn object
        GIDSignIn.sharedInstance().delegate = self
        GIDSignIn.sharedInstance().uiDelegate = self
        
        // Create a tap gesture recognizer within the email sign up button (UIView)
        let emailButtonTappedGesture = UITapGestureRecognizer(target: self, action: #selector(SignUpViewController.handleSignUp))
        self.emailSignupButtonView.addGestureRecognizer(emailButtonTappedGesture)
        
        // Create a tap gesture recognizer within the Google sign up button (UIView)
        let googleButtonTappedGesture = UITapGestureRecognizer(target: self, action: #selector(SignUpViewController.performGoogleSignUp))
        self.googleSignupButtonView.addGestureRecognizer(googleButtonTappedGesture)
        
    }
    
    
    // MARK: - Create User
    
    func createUser(withEmail email: String, password: String, username: String) {
        // Attempt to create user if username is unique
        Auth.auth().createUser(withEmail: email, password: password) { (result, error) in
            // General sign up error
            if let error = error {
                print("Failed to sign user up with error: ", error.localizedDescription)
                let errorAlert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
                errorAlert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                self.present(errorAlert, animated: true)
                return
            }
            
            // Get the unique userID of the current user signing up
            guard let userID = result?.user.uid else { return }
        
            let userInfo = ["username": username, "email": email, "account-type": "Email"]
            
            // Update the database for the userID above with the email address & username entered
            Database.database().reference().child("users").child(userID).updateChildValues(userInfo, withCompletionBlock: { (error, ref) in
                if let error = error {
                    print("Failed to updated database with error: ", error.localizedDescription)
                    return
                }
                print("Successfully signed user up...")
                self.performSegue(withIdentifier: "signupSegue", sender: self)
            })
    
        }
    }
    
    
    // MARK: - Helper Functions & Actions
    
    @objc func handleSignUp() {
        guard let email = emailField.text else { return }
        guard let username = usernameField.text else { return }
        guard let password = passwordField.text else { return }
        guard let confirmPassword = confirmPasswordField.text else { return }
        
        if username == "" {
            print("The username field is empty. Please input a username and try to sign up again!")
            let emptyUsernameAlert = UIAlertController(title: "Empty username field", message: "The username field is empty. Please input a username and try to sign up again.", preferredStyle: .alert)
            emptyUsernameAlert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            self.present(emptyUsernameAlert, animated: true)
            return
        } else if email == "" {
            print("The email field is empty. Please input an email address and try to sign up again!")
            let emptyEmailAlert = UIAlertController(title: "Empty email field", message: "The email field is empty. Please input an email address and try to sign up again.", preferredStyle: .alert)
            emptyEmailAlert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            self.present(emptyEmailAlert, animated: true)
            return
        } else if password == "" {
            print("The first password field is empty. Please input a password and try to sign up again!")
            let emptyPasswordAlert = UIAlertController(title: "Empty password field", message: "The first password field is empty. Please input a password and try to sign up again.", preferredStyle: .alert)
            emptyPasswordAlert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            self.present(emptyPasswordAlert, animated: true)
            return
        } else if confirmPassword == "" {
            print("The second password field is empty. Please input a confirmation password and try to sign up again!")
            let emptyConfirmPasswordAlert = UIAlertController(title: "Empty confirmation password field", message: "The second password field is empty. Please input a confirmation password and try to sign up again.", preferredStyle: .alert)
            emptyConfirmPasswordAlert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            self.present(emptyConfirmPasswordAlert, animated: true)
            return
        } else if password != confirmPassword {
            print("Please make sure both passwords match!")
            let passwordMismatchAlert = UIAlertController(title: "Password field mismatch", message: "The passwords entered do not match. Make sure they match and then try to sign up again.", preferredStyle: .alert)
            passwordMismatchAlert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            self.present(passwordMismatchAlert, animated: true)
            return
        }
        
        // Make sure the username user entered is unique
        Database.database().reference().child("users").queryOrdered(byChild: "username").queryEqual(toValue: username).observeSingleEvent(of: .value, with: { (snapshot) in
            print(snapshot.value!) // Snapshot of keys/values in DB that have matching username
            // If username is not unique, alert user and cancel sign up process
            if (!(snapshot.value! is NSNull)) {
                print("Username already exists!")
                let usernameExistsAlert = UIAlertController(title: "Username exists", message: "The username entered already exists. Please input another username and try to sign up again.", preferredStyle: .alert)
                usernameExistsAlert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                self.present(usernameExistsAlert, animated: true)
                return
            }
        })
        
        // Create user if validation throws no error
        createUser(withEmail: email, password: password, username: username)
    }
    
    // Google signup button pressed --> CUSTOM
    @objc func performGoogleSignUp(_ sender: UIView) {
        GIDSignIn.sharedInstance().signIn()
        
    }

    // Google signup button pressed
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        if let error = error {
            print("Google sign up error occured with error: ", error.localizedDescription)
            // TODO: - Remove googleSigninAlert before release
            let googleSignupAlert = UIAlertController(title: "Google sign up error", message: "There was an error signing up with Google: \(error.localizedDescription)", preferredStyle: .alert)
            googleSignupAlert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            self.present(googleSignupAlert, animated: true)
            return
        } else {
            self.customActivityIndicator(self.view, startAnimate: true) // Start the loading indicator animation
            
            guard let authentication = user.authentication else { return }
            let credential = GoogleAuthProvider.credential(withIDToken: authentication.idToken, accessToken: authentication.accessToken)
            // Asynchronously signs in to Firebase with the given 3rd-party credentials (e.g. Google, Facebook) and returns additional identity provider data
            Auth.auth().signInAndRetrieveData(with: credential) { (result, error) in
                if error == nil {
                    guard let email = user.profile.email else { return }
                    self.checkForUsername {
                        print("Username has been checked for. Now handling Google login with username:", self.username)
                        self.handleGoogleLogin(forUserEmail: email, username: self.username)
                    }
                } else {
                    print(error as Any)
                    // TODO: - Remove firebaseAsyncSigninErrorAlert before release
                    let firebaseAsyncSigninErrorAlert = UIAlertController(title: "Firebase sign in error", message: "There was an error signing in to Firebase with the given Google credentials: \(error as Any)", preferredStyle: .alert)
                    firebaseAsyncSigninErrorAlert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                    self.present(firebaseAsyncSigninErrorAlert, animated: true)
                }
            }
        }
    }
    
    @objc func handleGoogleLogin(forUserEmail email: String, username: String) {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        
        // If user that is signing in with a Google account is not in the database, store their userID and email in the DB and segue them to the username creation screen
        Database.database().reference().child("users").queryOrdered(byChild: "email").queryEqual(toValue: email).observeSingleEvent(of: .value) { (snapshot) in
            print(snapshot.value!) // Snapshot of the keys/values in DB that have matching userID
            self.customActivityIndicator(self.view, startAnimate: false) // Stop the loading indicator animation
            print("Handling Google login with username:", username)
            
            if (!snapshot.exists()) {
                print("User ID:", userID, "and email:", email, "does not exist in the Firebase database. Updating the database...")
                
                let userInfo = [userID: ["email": email, "account-type": "Google"]]
                
                Database.database().reference().child("users").updateChildValues(userInfo, withCompletionBlock: { (error, ref) in
                    if let error = error {
                        print("Failed to update database with error: ", error.localizedDescription)
                        return
                    }
                    print("Successfully added Google user's userID and email address to Firebase database!")
                    
                    // Transfer user to username retrieval screen
                    self.takeUserToUsernameScreen()
                    
                })
            } else if (snapshot.exists() && self.username == "") {
                // If snapshot returns user with associated email AND that email doesn't have a username associated with it, send the user to the username creation screen.
                // If user signs in with Google and exists in the Firebase database but doesn't have a username, take them to the username creation screen. This scenario would happen if the user signed in with a Google account but didn't have an account to begin with. If that user exits and closes the app and then tries to sign in again, instead of being taking to the home page (which would result in an error since no stats are stored for that user), a check is performed to see if they created a username before exiting. If not, that means they didn't complete the survey either so the app takes them to the proper screen (to get the user's information)
                // Transfer user to username retrieval screen
                print("Username has not been created yet for:", userID, "Segueing to username creation screen...")
                self.takeUserToUsernameScreen()
            } else {
                print(NSStringFromClass(UIApplication.topViewController()!.classForCoder).components(separatedBy: ".").last!, type(of: NSStringFromClass(UIApplication.topViewController()!.classForCoder).components(separatedBy: ".").last!), "\n")
                // If user is on AccountSettingsViewController, check if user has an account (re-authenticate)
                if NSStringFromClass(UIApplication.topViewController()!.classForCoder).components(separatedBy: ".").last! == "AccountSettingsViewController" {
                    print("User has been signed in silently from LoginViewController...\n")
                    return
                } else { // If user is on LoginViewController (or any other VC)
                    print("Segueing home...\n")
                    // Transfer user to username retrieval screen
                    self.takeUserToHomeScreen()
                }
            }
        }
    }
    
    func checkForUsername(completion: @escaping () -> ()) {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        
        // If user that is signing in with a Google account is not in the database, store their userID and email in the DB and segue them to the username creation screen
        Database.database().reference().child("users/\(userID)/username").observeSingleEvent(of: .value) { (snapshot) in
            print(snapshot.value!) // Snapshot of the keys/values in DB that have matching userID
            if (!snapshot.exists()) {
                print("A username does not exist for user with userID:", userID)
                completion()
            } else {
                print("A username exists for user with userID:", userID)
                print("That username is:", snapshot.value!)
                self.username = snapshot.value! as! String
                completion()
            }
        }
    }
    
    
    // MARK: - Segues & Segue Animations
    
    func takeUserToHomeScreen() {
        let homeVC = UIStoryboard(name: "Home", bundle: nil).instantiateViewController(withIdentifier: "HomeViewController")
        self.segueToTop()
        UIApplication.topViewController()?.present(homeVC, animated: false, completion: nil)
    }
    
    func takeUserToUsernameScreen() {
        let getUsernameVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "GetUsernameViewController")
        self.segueToTop()
        UIApplication.topViewController()?.present(getUsernameVC, animated: false, completion: nil)
    }
    
//    // Right-to-left segue animation
//    func segueFromRight() {
//        let transition = CATransition()
//        transition.duration = 0.5
//        transition.type = CATransitionType.push
//        transition.subtype = CATransitionSubtype.fromRight
//        transition.timingFunction = CAMediaTimingFunction(name:CAMediaTimingFunctionName.easeInEaseOut)
//        self.view.window!.layer.add(transition, forKey: kCATransition)
//    }
    
    // Bottom-to-top segue animation
    func segueToTop() {
        let transition = CATransition()
        transition.duration = 0.5
        transition.type = CATransitionType.push
        transition.subtype = CATransitionSubtype.fromTop
        transition.timingFunction = CAMediaTimingFunction(name:CAMediaTimingFunctionName.easeInEaseOut)
        self.view.window?.layer.add(transition, forKey: kCATransition)
    }
    
    @IBAction func onTap(_ sender: Any) {
        view.endEditing(true)
    }
    

}

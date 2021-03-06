
//
//  LoginViewController.swift
//  Nutriq
//
//  Created by Michael Mcmanus on 4/12/19.
//  Copyright © 2019 NutriQ. All rights reserved.
//

import UIKit
import Firebase
import GoogleSignIn

class LoginViewController: UIViewController, GIDSignInDelegate, GIDSignInUIDelegate {


    // MARK: - Properties
    
    var username = ""
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var emailSigninButtonView: UIView!
    @IBOutlet weak var emailSigninLabel: UILabel!
    @IBOutlet weak var googleSigninButton: GIDSignInButton!
    @IBOutlet weak var googleSigninButtonView: UIView!
    @IBOutlet weak var googleSigninLabel: UILabel!
    
    
    // MARK: - Init

    override func viewDidLoad() {
        super.viewDidLoad()

        emailField.becomeFirstResponder()
        
        // Customize email signin button
        emailSigninButtonView.layer.cornerRadius = 5
        emailSigninButtonView.layer.masksToBounds = true
        emailSigninLabel.font = UIFont(name: "Roboto-Bold", size: 14)
        
        // Customize Google signin button
        googleSigninButtonView.layer.cornerRadius = 5
        googleSigninButtonView.layer.masksToBounds = true
        googleSigninLabel.font = UIFont(name: "Roboto-Bold", size: 14)
        
        // Set the UI delegate of the GIDSignIn object
        GIDSignIn.sharedInstance().delegate = self
        GIDSignIn.sharedInstance().uiDelegate = self
        
        // Create a tap gesture recognizer within the email sign up button (UIView)
        let emailButtonTappedGesture = UITapGestureRecognizer(target: self, action: #selector(LoginViewController.handleEmailLogin))
        self.emailSigninButtonView.addGestureRecognizer(emailButtonTappedGesture)
        
        // Create a tap gesture recognizer within the Google sign up button (UIView)
        let googleButtonTappedGesture = UITapGestureRecognizer(target: self, action: #selector(LoginViewController.performGoogleSignIn))
        self.googleSigninButtonView.addGestureRecognizer(googleButtonTappedGesture)
    }


    @IBAction func onForgotPasswordButtonPressed(_ sender: Any) {
        showResetPasswordPopup()
    }
    
    // MARK: - User Login
    // TODO: - Allow user to log in with either username or email? If one is empty, the other one must be filled out. Use the one that is filled out to complete the user log in.
    func logUserIn(withEmail email: String, password: String) {
        Auth.auth().signIn(withEmail: email, password: password) { (result, error) in
            if let error = error {
                print("Failed to sign user in with error: ", error.localizedDescription)
                // If user input invalid password
                if error.localizedDescription == "The password is invalid or the user does not have a password." {
                    let invalidPasswordAlert = UIAlertController(title: "Invalid password", message: "The password you entered is invalid. Please try again.", preferredStyle: .alert)
                    invalidPasswordAlert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                    self.present(invalidPasswordAlert, animated: true)
                } // If user input invalid username
                else if error.localizedDescription == "There is no user record corresponding to this identifier. The user may have been deleted." {
                    let invalidUsernameAlert = UIAlertController(title: "Invalid email", message: "The email address you entered is invalid. Please try again.", preferredStyle: .alert)
                    invalidUsernameAlert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                    self.present(invalidUsernameAlert, animated: true)
                }
                return
            }
            print("Successfully logged user in...")
            self.takeUserToHomeScreen()
        }
    }


    // MARK: - Helper Functions & Actions

    @objc func handleEmailLogin() {
        guard let email = emailField.text else { return }
        guard let password = passwordField.text else { return }

        if email == "" {
            print("The email field is empty. Please input an email address and try to sign up again!")
            let emptyEmailAlert = UIAlertController(title: "Empty email field", message: "The email field is empty. Please input an email address and try to sign up again.", preferredStyle: .alert)
            emptyEmailAlert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            self.present(emptyEmailAlert, animated: true)
            return
        } else if password == "" {
            print("The password field is empty. Please input a password and try to sign up again!")
            let emptyPasswordAlert = UIAlertController(title: "Empty password field", message: "The first password field is empty. Please input a password and try to sign up again.", preferredStyle: .alert)
            emptyPasswordAlert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            self.present(emptyPasswordAlert, animated: true)
            return
        } else {
            logUserIn(withEmail: email, password: password)
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
    

    // Google login button pressed
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        if let error = error {
            print("Google sign in error occured with error: ", error.localizedDescription)
            // TODO: - Remove googleSigninAlert before release
            let googleSigninAlert = UIAlertController(title: "Google sign in error", message: "There was an error logging in with Google: \(error.localizedDescription)", preferredStyle: .alert)
            googleSigninAlert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            self.present(googleSigninAlert, animated: true)
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

    // Google login button pressed
    @objc func performGoogleSignIn(_ sender: UIView) {
        GIDSignIn.sharedInstance().signIn()
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
    
    // Pops up a small view controller which reauthenticates the current user by getting user to input current password
    func showResetPasswordPopup() {
        let resetPasswordVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ForgotPasswordViewController") as! ForgotPasswordViewController
        self.addChild(resetPasswordVC)
        resetPasswordVC.view.frame = self.view.frame
        self.view.addSubview(resetPasswordVC.view)
        resetPasswordVC.didMove(toParent: self)
    }
    
    @IBAction func onTap(_ sender: Any) {
        view.endEditing(true)
    }
    


}

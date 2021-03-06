//
//  ProfileViewController.swift
//  Nutriq
//
//  Created by Michael Mcmanus on 5/1/19.
//  Copyright © 2019 NutriQ. All rights reserved.
//

import UIKit
import Firebase

// Instantiate the ProfileViewController to allow for its functions to be called outside of itself; More specifically, the 'loadUserData' function which will update the profile screen with the most current stats after the user updates their weight
var profileVCInstance = ProfileViewController()

class ProfileViewController: UIViewController {
    
    
    // MARK: - Properties

    @IBOutlet weak var settingsBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var welcomeUsernameLabel: UILabel!
    
    // User's progress
    @IBOutlet weak var progressView: UIView!
    @IBOutlet weak var currentWeightView: UIView!
    @IBOutlet weak var beginningWeightView: UIView!
    @IBOutlet weak var goalWeightView: UIView!
    @IBOutlet weak var currentWeightLabel: UILabel!
    @IBOutlet weak var beginningWeightLabel: UILabel!
    @IBOutlet weak var goalWeightLabel: UILabel!
    @IBOutlet weak var progressMessageLabel: UILabel!
    @IBOutlet weak var motivationalMessageLabel: UILabel!
    @IBOutlet weak var updateWeightButton: ShadowButton!
    
    // User's goals
    @IBOutlet weak var goalsView: UIView!
    @IBOutlet weak var maintenanceCaloriesView: UIView!
    @IBOutlet weak var goalCaloriesView: UIView!
    @IBOutlet weak var maintenanceCaloriesLabel: UILabel!
    @IBOutlet weak var goalCaloriesLabel: UILabel!
    @IBOutlet weak var weeklyGoalMessageLabel: UILabel!
    @IBOutlet weak var activityLevelMessageLabel: UILabel!
    @IBOutlet weak var updateGoalsButton: ShadowButton!
    
    
    // MARK: - Init
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        profileVCInstance = self
        
        self.title = "Profile"
        
        // Make the labels the change transparent for a fade in animation
        welcomeUsernameLabel.alpha = 0.0
        currentWeightLabel.alpha = 0.0
        beginningWeightLabel.alpha = 0.0
        goalWeightLabel.alpha = 0.0
        progressMessageLabel.alpha = 0.0
        motivationalMessageLabel.alpha = 0.0
        maintenanceCaloriesLabel.alpha = 0.0
        goalCaloriesLabel.alpha = 0.0
        weeklyGoalMessageLabel.alpha = 0.0
        activityLevelMessageLabel.alpha = 0.0
        
        // Customize the views
        progressView.layer.cornerRadius = 5.0
        currentWeightView.layer.cornerRadius = 5.0
        beginningWeightView.layer.cornerRadius = 5.0
        goalWeightView.layer.cornerRadius = 5.0
        goalsView.layer.cornerRadius = 5.0
        maintenanceCaloriesView.layer.cornerRadius = 5.0
        goalCaloriesView.layer.cornerRadius = 5.0
    }
    
    override func viewWillAppear(_ animated: Bool) {
        getAndLoadUserData()
    }
    
    
    // MARK: - Helper Functions & Actions
    
    func getAndLoadUserData() {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        
        let userReference = Database.database().reference().child("users/\(userID)")
        
        userReference.observeSingleEvent(of: .value) { (snapshot) in
            print("Snapshot of the user's information:\n", snapshot.value!) // Returns snapshot of all user's information (everything under userID)
            let snapshotValue = snapshot.value! as? NSDictionary
            let username = snapshotValue?["username"] as! String
            
            // Health stats object
            let healthStatsSnapshotValue = snapshotValue?["health-stats"] as? NSDictionary
            let activityLevel = healthStatsSnapshotValue?["activity-level"] as! String
            let currentWeight = healthStatsSnapshotValue?["current-weight-pounds"] as! Double
            let beginningWeight = healthStatsSnapshotValue?["beginning-weight-pounds"] as! Double
            let goalWeight = healthStatsSnapshotValue?["goal-weight-pounds"] as! Double
            let weightLeftUntilGoal = healthStatsSnapshotValue?["weight-left-until-goal"] as! Double
            let overallGoal = healthStatsSnapshotValue?["overall-goal"] as! String
            let weeklyGoal = healthStatsSnapshotValue?["weekly-goal"] as! Double
            let maintenanceCalories = healthStatsSnapshotValue?["maintenance-calories"] as! Int
            let goalCalories = healthStatsSnapshotValue?["goal-calories"] as! Int
        
            
            // Set the labels
            self.welcomeUsernameLabel.text = "Welcome, \(username)"
            self.currentWeightLabel.text = "\(currentWeight) pounds"
            self.beginningWeightLabel.text = "\(beginningWeight) pounds"
            self.goalWeightLabel.text = "\(goalWeight) pounds"
            
            // Progress message label
            if overallGoal == "Lose" && currentWeight < beginningWeight {
                self.progressMessageLabel.text = "Weight Loss Progress - \((((beginningWeight - currentWeight) * 10).rounded(.toNearestOrEven) / 10)) pounds lost"
            } else if overallGoal == "Gain" && currentWeight > beginningWeight {
                self.progressMessageLabel.text = "Weight Gain Progress - \((((currentWeight - beginningWeight) * 10).rounded(.toNearestOrEven) / 10)) pounds gained"
            } else {
                self.progressMessageLabel.text = ""
            }
            
            // Motivational message label
            if weightLeftUntilGoal > 0 && (overallGoal == "Lose" && currentWeight > goalWeight) || (overallGoal == "Gain" && currentWeight < goalWeight) {
                self.motivationalMessageLabel.text = "You are only \(weightLeftUntilGoal) pounds away from your goal! Keep going!"
            } else {
                self.motivationalMessageLabel.text = "Congratulations, \(username)! You reached your goal and we're so proud of you for it! Try setting a new goal if you're up for it!"
            }
            
            self.maintenanceCaloriesLabel.text = "\(maintenanceCalories)"
            self.goalCaloriesLabel.text = "\(goalCalories)"
            
            // Customize the weekly goal message
            if overallGoal != "Maintain" {
                self.weeklyGoalMessageLabel.text = "Weekly Goal - \(overallGoal) \(abs(weeklyGoal)) pounds per week"
            } else {
                self.weeklyGoalMessageLabel.text = "Maintain weight"
            }
            
            self.activityLevelMessageLabel.text = "Activity Level - \(activityLevel)"
            
            
            // Animate the labels
            UIView.animate(withDuration: 0.5, animations: {
                self.welcomeUsernameLabel.alpha = 1
                self.currentWeightLabel.alpha = 1
                self.beginningWeightLabel.alpha = 1
                self.goalWeightLabel.alpha = 1
                self.progressMessageLabel.alpha = 1
                self.motivationalMessageLabel.alpha = 1
                self.maintenanceCaloriesLabel.alpha = 1
                self.goalCaloriesLabel.alpha = 1
                self.weeklyGoalMessageLabel.alpha = 1
                self.activityLevelMessageLabel.alpha = 1
            })
            
        }
    }
    
    @IBAction func onUpdateWeightButtonPressed(_ sender: Any) {
        showUpdateWeightPopup()
    }
    
    func showUpdateWeightPopup() {
        let updateWeightVC = UIStoryboard(name: "Profile", bundle: nil).instantiateViewController(withIdentifier: "UpdateWeightViewController") as! UpdateWeightViewController
        updateWeightVC.view.frame = self.view.frame
        self.view.addSubview(updateWeightVC.view)
        self.addChild(updateWeightVC)
        updateWeightVC.didMove(toParent: self)
        
    }
}


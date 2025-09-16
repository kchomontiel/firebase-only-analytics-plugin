#!/usr/bin/env node

/**
 * Hook script to initialize Firebase in AppDelegate
 * This ensures Firebase is properly configured before any plugin methods are called
 */

var fs = require("fs");
var path = require("path");

module.exports = function (context) {
  var Q = require("q");
  var deferral = Q.defer();

  // Only run for iOS platform
  if (!context.opts.platforms || context.opts.platforms.indexOf("ios") === -1) {
    deferral.resolve();
    return deferral.promise;
  }

  console.log("FirebasePlugin: Initializing Firebase in AppDelegate...");

  try {
    // Path to the iOS project
    var iosProjectPath = path.join(context.opts.projectRoot, "platforms", "ios");
    
    if (!fs.existsSync(iosProjectPath)) {
      console.log("FirebasePlugin: iOS platform not found, skipping Firebase initialization");
      deferral.resolve();
      return deferral.promise;
    }

    // Find the main app directory
    var appDirs = fs.readdirSync(iosProjectPath).filter(function (dir) {
      return !dir.endsWith(".xcodeproj") && 
             !dir.endsWith(".xcworkspace") && 
             !dir.startsWith("Pods") &&
             fs.statSync(path.join(iosProjectPath, dir)).isDirectory();
    });

    if (appDirs.length === 0) {
      console.log("FirebasePlugin: No app directory found, skipping Firebase initialization");
      deferral.resolve();
      return deferral.promise;
    }

    var appDir = appDirs[0]; // Use the first app directory
    var appDelegatePath = path.join(iosProjectPath, appDir, "AppDelegate.m");

    if (!fs.existsSync(appDelegatePath)) {
      console.log("FirebasePlugin: AppDelegate.m not found, skipping Firebase initialization");
      deferral.resolve();
      return deferral.promise;
    }

    // Read AppDelegate.m
    var appDelegateContent = fs.readFileSync(appDelegatePath, "utf8");

    // Check if Firebase is already initialized
    if (appDelegateContent.includes("FirebaseApp.configure()") || 
        appDelegateContent.includes("#import <Firebase/Firebase.h>")) {
      console.log("FirebasePlugin: Firebase already initialized in AppDelegate");
      deferral.resolve();
      return deferral.promise;
    }

    // Add Firebase import
    var firebaseImport = "#import <Firebase/Firebase.h>\n";
    if (!appDelegateContent.includes(firebaseImport)) {
      appDelegateContent = firebaseImport + appDelegateContent;
    }

    // Add Firebase initialization in didFinishLaunchingWithOptions
    var firebaseInitCode = `
    // Initialize Firebase
    [FIRApp configure];
    `;

    // Find the didFinishLaunchingWithOptions method and add Firebase initialization
    var methodRegex = /- \(BOOL\)application:\(UIApplication \*\)application didFinishLaunchingWithOptions:\(NSDictionary \*\)launchOptions\s*\{/;
    if (methodRegex.test(appDelegateContent)) {
      appDelegateContent = appDelegateContent.replace(methodRegex, function(match) {
        return match + firebaseInitCode;
      });
    }

    // Write the modified AppDelegate.m
    fs.writeFileSync(appDelegatePath, appDelegateContent);
    console.log("FirebasePlugin: Firebase initialization added to AppDelegate.m");

    deferral.resolve();

  } catch (error) {
    console.error("FirebasePlugin: Error initializing Firebase:", error);
    // Don't fail the build, just continue
    deferral.resolve();
  }

  return deferral.promise;
};

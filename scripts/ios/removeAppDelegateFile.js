#!/usr/bin/env node

/**
 * Hook script to remove AppDelegate+FirebasePlugin.swift file if it exists
 * This ensures the problematic file is completely removed from the project
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

  console.log("FirebasePlugin: Removing AppDelegate+FirebasePlugin.swift file if it exists...");

  try {
    // Path to the iOS project
    var iosProjectPath = path.join(context.opts.projectRoot, "platforms", "ios");
    
    if (!fs.existsSync(iosProjectPath)) {
      console.log("FirebasePlugin: iOS platform not found, skipping file removal");
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
      console.log("FirebasePlugin: No app directory found, skipping file removal");
      deferral.resolve();
      return deferral.promise;
    }

    var appDir = appDirs[0];
    var pluginPath = path.join(iosProjectPath, appDir, "Plugins", "cordova-plugin-firebase");
    
    if (fs.existsSync(pluginPath)) {
      var appDelegateFile = path.join(pluginPath, "AppDelegate+FirebasePlugin.swift");
      
      if (fs.existsSync(appDelegateFile)) {
        console.log("FirebasePlugin: Found AppDelegate+FirebasePlugin.swift, removing it...");
        fs.unlinkSync(appDelegateFile);
        console.log("FirebasePlugin: AppDelegate+FirebasePlugin.swift removed successfully");
      } else {
        console.log("FirebasePlugin: AppDelegate+FirebasePlugin.swift not found, nothing to remove");
      }
    } else {
      console.log("FirebasePlugin: Plugin directory not found, skipping file removal");
    }

    deferral.resolve();

  } catch (error) {
    console.error("FirebasePlugin: Error removing AppDelegate file:", error);
    // Don't fail the build, just continue
    deferral.resolve();
  }

  return deferral.promise;
};

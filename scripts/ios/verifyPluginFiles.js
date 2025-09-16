#!/usr/bin/env node

/**
 * Hook script to verify that only the correct plugin files exist
 * This ensures no problematic files are present
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

  console.log("FirebasePlugin: Verifying plugin files...");

  try {
    // Path to the iOS project
    var iosProjectPath = path.join(context.opts.projectRoot, "platforms", "ios");
    
    if (!fs.existsSync(iosProjectPath)) {
      console.log("FirebasePlugin: iOS platform not found, skipping verification");
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
      console.log("FirebasePlugin: No app directory found, skipping verification");
      deferral.resolve();
      return deferral.promise;
    }

    var appDir = appDirs[0];
    var pluginPath = path.join(iosProjectPath, appDir, "Plugins", "cordova-plugin-firebase");
    
    if (fs.existsSync(pluginPath)) {
      console.log("FirebasePlugin: Checking plugin files in:", pluginPath);
      
      var files = fs.readdirSync(pluginPath);
      var hasFirebasePlugin = false;
      var hasAppDelegate = false;
      
      files.forEach(function(file) {
        if (file === "FirebasePlugin.swift") {
          hasFirebasePlugin = true;
          console.log("FirebasePlugin: ✅ Found FirebasePlugin.swift");
        } else if (file.includes("AppDelegate") && file.endsWith(".swift")) {
          hasAppDelegate = true;
          console.log("FirebasePlugin: ❌ Found problematic file:", file);
        }
      });
      
      if (hasFirebasePlugin && !hasAppDelegate) {
        console.log("FirebasePlugin: ✅ Plugin files are correct - only FirebasePlugin.swift exists");
      } else if (!hasFirebasePlugin) {
        console.log("FirebasePlugin: ❌ FirebasePlugin.swift not found!");
      } else if (hasAppDelegate) {
        console.log("FirebasePlugin: ❌ Problematic AppDelegate files still exist!");
      }
    } else {
      console.log("FirebasePlugin: Plugin directory not found");
    }

    deferral.resolve();

  } catch (error) {
    console.error("FirebasePlugin: Error verifying plugin files:", error);
    // Don't fail the build, just continue
    deferral.resolve();
  }

  return deferral.promise;
};

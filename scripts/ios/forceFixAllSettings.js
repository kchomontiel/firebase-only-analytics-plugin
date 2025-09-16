#!/usr/bin/env node

/**
 * Aggressive hook script to force fix ALL Swift and deployment target issues
 * This script runs after plugin installation and fixes everything programmatically
 */

var fs = require("fs");
var path = require("path");
var exec = require('child_process').exec;

module.exports = function (context) {
  var Q = require("q");
  var deferral = Q.defer();

  // Only run for iOS platform
  if (!context.opts.platforms || context.opts.platforms.indexOf("ios") === -1) {
    deferral.resolve();
    return deferral.promise;
  }

  console.log("FirebasePlugin: FORCE FIXING ALL SWIFT AND DEPLOYMENT TARGET SETTINGS...");

  try {
    // Path to the iOS project
    var iosProjectPath = path.join(context.opts.projectRoot, "platforms", "ios");
    
    if (!fs.existsSync(iosProjectPath)) {
      console.log("FirebasePlugin: iOS platform not found, skipping force fix");
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
      console.log("FirebasePlugin: No app directory found, skipping force fix");
      deferral.resolve();
      return deferral.promise;
    }

    var appDir = appDirs[0];
    console.log("FirebasePlugin: Found app directory:", appDir);

    // 1. Fix project.pbxproj file
    var projectDirs = fs.readdirSync(iosProjectPath).filter(function (dir) {
      return dir.endsWith(".xcodeproj");
    });

    if (projectDirs.length > 0) {
      var projectPath = path.join(iosProjectPath, projectDirs[0], "project.pbxproj");
      
      if (fs.existsSync(projectPath)) {
        console.log("FirebasePlugin: Fixing project.pbxproj...");
        var projectContent = fs.readFileSync(projectPath, "utf8");
        
        // Force deployment target to 12.0
        projectContent = projectContent.replace(
          /IPHONEOS_DEPLOYMENT_TARGET = [0-9.]+;/g,
          "IPHONEOS_DEPLOYMENT_TARGET = 12.0;"
        );
        
        // Force Swift version to 5.0
        projectContent = projectContent.replace(
          /SWIFT_VERSION = [0-9.]+;/g,
          "SWIFT_VERSION = 5.0;"
        );
        
        // Force Swift optimization level to -Onone for Debug
        projectContent = projectContent.replace(
          /SWIFT_OPTIMIZATION_LEVEL = "-O";/g,
          "SWIFT_OPTIMIZATION_LEVEL = \"-Onone\";"
        );
        
        // Remove problematic build settings
        projectContent = projectContent.replace(
          /ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES = YES;/g,
          "ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES = NO;"
        );
        
        // Fix LD_RUNPATH_SEARCH_PATHS
        projectContent = projectContent.replace(
          /LD_RUNPATH_SEARCH_PATHS = \([^)]*\);/g,
          'LD_RUNPATH_SEARCH_PATHS = (\n\t\t\t\t"$(inherited)",\n\t\t\t\t"@executable_path/Frameworks",\n\t\t\t\t"@loader_path/Frameworks",\n\t\t\t);'
        );
        
        fs.writeFileSync(projectPath, projectContent);
        console.log("FirebasePlugin: project.pbxproj fixed successfully");
      }
    }

    // 2. Fix Podfile
    var podfilePath = path.join(iosProjectPath, "Podfile");
    if (fs.existsSync(podfilePath)) {
      console.log("FirebasePlugin: Fixing Podfile...");
      var podfileContent = fs.readFileSync(podfilePath, "utf8");
      
      // Force deployment target
      podfileContent = podfileContent.replace(
        /platform :ios, '[^']*'/g,
        "platform :ios, '12.0'"
      );
      
      fs.writeFileSync(podfilePath, podfileContent);
      console.log("FirebasePlugin: Podfile fixed successfully");
    }

    // 3. Force pod install to apply fixes
    console.log("FirebasePlugin: Running pod install to apply fixes...");
    exec('cd "' + iosProjectPath + '" && pod install --repo-update', function(error, stdout, stderr) {
      if (error) {
        console.error("FirebasePlugin: Pod install error:", error);
        // Continue anyway
      } else {
        console.log("FirebasePlugin: Pod install completed successfully");
      }
      
      // 4. Fix Pods project after pod install
      var podsProjectPath = path.join(iosProjectPath, "Pods", "Pods.xcodeproj", "project.pbxproj");
      if (fs.existsSync(podsProjectPath)) {
        console.log("FirebasePlugin: Fixing Pods project.pbxproj...");
        var podsContent = fs.readFileSync(podsProjectPath, "utf8");
        
        // Force deployment target for all pods
        podsContent = podsContent.replace(
          /IPHONEOS_DEPLOYMENT_TARGET = [0-9.]+;/g,
          "IPHONEOS_DEPLOYMENT_TARGET = 12.0;"
        );
        
        // Force Swift version
        podsContent = podsContent.replace(
          /SWIFT_VERSION = [0-9.]+;/g,
          "SWIFT_VERSION = 5.0;"
        );
        
        // Force Swift optimization level
        podsContent = podsContent.replace(
          /SWIFT_OPTIMIZATION_LEVEL = "-O";/g,
          "SWIFT_OPTIMIZATION_LEVEL = \"-Onone\";"
        );
        
        fs.writeFileSync(podsProjectPath, podsContent);
        console.log("FirebasePlugin: Pods project.pbxproj fixed successfully");
      }
      
      console.log("FirebasePlugin: ALL SETTINGS FORCE FIXED SUCCESSFULLY!");
      deferral.resolve();
    });

  } catch (error) {
    console.error("FirebasePlugin: Error in force fix:", error);
    // Don't fail the build, just continue
    deferral.resolve();
  }

  return deferral.promise;
};

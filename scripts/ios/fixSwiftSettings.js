#!/usr/bin/env node

/**
 * Hook script to fix Swift settings and deployment targets
 * This ensures all Swift-related build settings are properly configured
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

  console.log("FirebasePlugin: Fixing Swift settings and deployment targets...");

  try {
    // Path to the iOS project
    var iosProjectPath = path.join(context.opts.projectRoot, "platforms", "ios");
    
    if (!fs.existsSync(iosProjectPath)) {
      console.log("FirebasePlugin: iOS platform not found, skipping Swift settings fix");
      deferral.resolve();
      return deferral.promise;
    }

    // Fix project.pbxproj file
    var projectPbxprojPath = path.join(iosProjectPath, "*.xcodeproj", "project.pbxproj");
    var projectDirs = fs.readdirSync(iosProjectPath).filter(function (dir) {
      return dir.endsWith(".xcodeproj");
    });

    if (projectDirs.length > 0) {
      var actualProjectPath = path.join(iosProjectPath, projectDirs[0], "project.pbxproj");
      
      if (fs.existsSync(actualProjectPath)) {
        var projectContent = fs.readFileSync(actualProjectPath, "utf8");
        
        // Fix deployment targets
        projectContent = projectContent.replace(
          /IPHONEOS_DEPLOYMENT_TARGET = [0-9.]+;/g,
          "IPHONEOS_DEPLOYMENT_TARGET = 12.0;"
        );
        
        // Fix Swift version
        projectContent = projectContent.replace(
          /SWIFT_VERSION = [0-9.]+;/g,
          "SWIFT_VERSION = 5.0;"
        );
        
        // Fix Swift optimization level for Debug
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
        
        fs.writeFileSync(actualProjectPath, projectContent);
        console.log("FirebasePlugin: Fixed project.pbxproj Swift settings");
      }
    }

    // Fix Podfile
    var podfilePath = path.join(iosProjectPath, "Podfile");
    if (fs.existsSync(podfilePath)) {
      var podfileContent = fs.readFileSync(podfilePath, "utf8");
      
      // Ensure deployment target is set
      if (!podfileContent.includes("platform :ios, '12.0'")) {
        podfileContent = podfileContent.replace(
          /platform :ios, '[^']*'/g,
          "platform :ios, '12.0'"
        );
      }
      
      fs.writeFileSync(podfilePath, podfileContent);
      console.log("FirebasePlugin: Fixed Podfile deployment target");
    }

    deferral.resolve();

  } catch (error) {
    console.error("FirebasePlugin: Error fixing Swift settings:", error);
    // Don't fail the build, just continue
    deferral.resolve();
  }

  return deferral.promise;
};

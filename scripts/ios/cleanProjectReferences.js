#!/usr/bin/env node

/**
 * Hook script to clean project references to AppDelegate+FirebasePlugin.swift
 * This removes the file from Xcode project if it's still referenced
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

  console.log("FirebasePlugin: Cleaning project references to AppDelegate+FirebasePlugin.swift...");

  try {
    // Path to the iOS project
    var iosProjectPath = path.join(context.opts.projectRoot, "platforms", "ios");
    
    if (!fs.existsSync(iosProjectPath)) {
      console.log("FirebasePlugin: iOS platform not found, skipping project cleanup");
      deferral.resolve();
      return deferral.promise;
    }

    // Find project.pbxproj file
    var projectDirs = fs.readdirSync(iosProjectPath).filter(function (dir) {
      return dir.endsWith(".xcodeproj");
    });

    if (projectDirs.length > 0) {
      var projectPath = path.join(iosProjectPath, projectDirs[0], "project.pbxproj");
      
      if (fs.existsSync(projectPath)) {
        console.log("FirebasePlugin: Cleaning project.pbxproj references...");
        var projectContent = fs.readFileSync(projectPath, "utf8");
        
        // Remove any references to AppDelegate+FirebasePlugin.swift
        var originalContent = projectContent;
        
        // Remove file references
        projectContent = projectContent.replace(
          /\/\* AppDelegate\+FirebasePlugin\.swift in Sources \*\/ = {isa = PBXBuildFile; fileRef = [^;]+; };[\r\n]*/g,
          ""
        );
        
        // Remove file references
        projectContent = projectContent.replace(
          /[A-F0-9]{24} \/\* AppDelegate\+FirebasePlugin\.swift \*\/ = {isa = PBXFileReference; lastKnownFileType = sourcecode\.swift; path = "AppDelegate\+FirebasePlugin\.swift"; sourceTree = "<group>"; };[\r\n]*/g,
          ""
        );
        
        // Remove from build phases
        projectContent = projectContent.replace(
          /[A-F0-9]{24} \/\* AppDelegate\+FirebasePlugin\.swift in Sources \*\/,[\r\n]*/g,
          ""
        );
        
        // Remove from groups
        projectContent = projectContent.replace(
          /[A-F0-9]{24} \/\* AppDelegate\+FirebasePlugin\.swift \*\/,[\r\n]*/g,
          ""
        );
        
        if (projectContent !== originalContent) {
          fs.writeFileSync(projectPath, projectContent);
          console.log("FirebasePlugin: project.pbxproj cleaned successfully");
        } else {
          console.log("FirebasePlugin: No AppDelegate+FirebasePlugin.swift references found in project.pbxproj");
        }
      }
    }

    deferral.resolve();

  } catch (error) {
    console.error("FirebasePlugin: Error cleaning project references:", error);
    // Don't fail the build, just continue
    deferral.resolve();
  }

  return deferral.promise;
};

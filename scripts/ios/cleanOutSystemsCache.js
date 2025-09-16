#!/usr/bin/env node

/**
 * Hook script to clean OutSystems cache and ensure fresh plugin installation
 * This helps resolve caching issues that prevent plugin updates
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

  console.log("FirebasePlugin: Cleaning OutSystems cache and ensuring fresh installation...");

  try {
    // Path to the iOS project
    var iosProjectPath = path.join(context.opts.projectRoot, "platforms", "ios");
    
    if (!fs.existsSync(iosProjectPath)) {
      console.log("FirebasePlugin: iOS platform not found, skipping cache cleanup");
      deferral.resolve();
      return deferral.promise;
    }

    // Clean any cached plugin files
    var pluginCachePath = path.join(iosProjectPath, "Plugins", "cordova-plugin-firebase");
    if (fs.existsSync(pluginCachePath)) {
      console.log("FirebasePlugin: Found plugin cache, cleaning...");
      
      // Remove any cached AppDelegate files
      var files = fs.readdirSync(pluginCachePath);
      files.forEach(function(file) {
        if (file.includes("AppDelegate") && file.endsWith(".swift")) {
          var filePath = path.join(pluginCachePath, file);
          try {
            fs.unlinkSync(filePath);
            console.log("FirebasePlugin: Removed cached file:", file);
          } catch (error) {
            console.log("FirebasePlugin: Could not remove cached file:", file, error.message);
          }
        }
      });
    }

    // Clean node_modules cache if it exists
    var nodeModulesPath = path.join(context.opts.projectRoot, "node_modules", "cordova-plugin-firebase");
    if (fs.existsSync(nodeModulesPath)) {
      console.log("FirebasePlugin: Found node_modules cache, cleaning...");
      try {
        exec('rm -rf "' + nodeModulesPath + '"', function(error, stdout, stderr) {
          if (error) {
            console.log("FirebasePlugin: Could not clean node_modules cache:", error.message);
          } else {
            console.log("FirebasePlugin: node_modules cache cleaned successfully");
          }
        });
      } catch (error) {
        console.log("FirebasePlugin: Error cleaning node_modules cache:", error.message);
      }
    }

    deferral.resolve();

  } catch (error) {
    console.error("FirebasePlugin: Error cleaning OutSystems cache:", error);
    // Don't fail the build, just continue
    deferral.resolve();
  }

  return deferral.promise;
};

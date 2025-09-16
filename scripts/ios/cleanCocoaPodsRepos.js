#!/usr/bin/env node

/**
 * Hook script to clean CocoaPods repositories and resolve conflicts
 * This ensures no duplicate specifications are found
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

  console.log("FirebasePlugin: Cleaning CocoaPods repositories to resolve conflicts...");

  try {
    // Clean CocoaPods repositories
    exec('pod repo remove trunk', function(error, stdout, stderr) {
      if (error) {
        console.log("FirebasePlugin: trunk repo not found or already removed");
      } else {
        console.log("FirebasePlugin: Removed trunk repo");
      }
      
      exec('pod repo remove cocoapods', function(error, stdout, stderr) {
        if (error) {
          console.log("FirebasePlugin: cocoapods repo not found or already removed");
        } else {
          console.log("FirebasePlugin: Removed cocoapods repo");
        }
        
        // Re-add only the CDN trunk repo
        exec('pod repo add trunk https://cdn.cocoapods.org/', function(error, stdout, stderr) {
          if (error) {
            console.log("FirebasePlugin: Warning - could not add CDN trunk repo:", error.message);
          } else {
            console.log("FirebasePlugin: Added CDN trunk repo");
          }
          
          console.log("FirebasePlugin: CocoaPods repositories cleaned successfully");
          deferral.resolve();
        });
      });
    });

  } catch (error) {
    console.error("FirebasePlugin: Error cleaning CocoaPods repositories:", error);
    // Don't fail the build, just continue
    deferral.resolve();
  }

  return deferral.promise;
};

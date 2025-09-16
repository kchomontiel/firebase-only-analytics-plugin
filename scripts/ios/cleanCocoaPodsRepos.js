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
    // Clean CocoaPods repositories and cache
    var commands = [
      'pod repo remove trunk || true',
      'pod repo remove cocoapods || true', 
      'pod cache clean --all || true',
      'pod repo add trunk https://cdn.cocoapods.org/ || true'
    ];
    
    var currentCommand = 0;
    
    function runNextCommand() {
      if (currentCommand >= commands.length) {
        console.log("FirebasePlugin: CocoaPods repositories cleaned successfully");
        deferral.resolve();
        return;
      }
      
      var command = commands[currentCommand];
      console.log("FirebasePlugin: Running:", command);
      
      exec(command, function(error, stdout, stderr) {
        if (error) {
          console.log("FirebasePlugin: Command completed with warnings:", error.message);
        } else {
          console.log("FirebasePlugin: Command completed successfully");
        }
        
        currentCommand++;
        runNextCommand();
      });
    }
    
    runNextCommand();

  } catch (error) {
    console.error("FirebasePlugin: Error cleaning CocoaPods repositories:", error);
    // Don't fail the build, just continue
    deferral.resolve();
  }

  return deferral.promise;
};

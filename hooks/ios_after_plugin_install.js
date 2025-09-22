#!/usr/bin/env node

/**
 * iOS Post-Install Hook for Firebase Analytics Plugin
 * Ensures GoogleService-Info.plist is properly copied to the iOS project
 */

const fs = require("fs");
const path = require("path");

module.exports = function (context) {
  const deferral = { resolve: () => {}, reject: () => {} };

  console.log("Firebase Analytics Plugin: Running iOS post-install hook...");

  // Check if we're running on iOS platform
  if (!context.opts.platforms || context.opts.platforms.indexOf("ios") === -1) {
    console.log("Firebase Analytics Plugin: Not iOS platform, skipping hook");
    return;
  }

  const platformPath = path.join(context.opts.projectRoot, "platforms", "ios");
  const googleServicesSourcePath = path.join(
    context.opts.projectRoot,
    "GoogleService-Info.plist"
  );
  const googleServicesTargetPath = path.join(
    platformPath,
    "GoogleService-Info.plist"
  );

  // Check if GoogleService-Info.plist exists in project root
  if (!fs.existsSync(googleServicesSourcePath)) {
    console.log(
      "Firebase Analytics Plugin: GoogleService-Info.plist not found in project root"
    );
    return;
  }

  // Copy GoogleService-Info.plist to the iOS platform directory
  try {
    fs.copyFileSync(googleServicesSourcePath, googleServicesTargetPath);
    console.log(
      "Firebase Analytics Plugin: Copied GoogleService-Info.plist to platforms/ios/"
    );
  } catch (error) {
    console.error(
      "Firebase Analytics Plugin: Error copying GoogleService-Info.plist:",
      error.message
    );
    return;
  }

  // Enable Firebase Analytics debug logging programmatically
  try {
    const swiftFilePath = path.join(context.opts.projectRoot, "platforms", "ios", "FirebaseAnalyticsPlugin.swift");
    if (fs.existsSync(swiftFilePath)) {
      let swiftContent = fs.readFileSync(swiftFilePath, "utf8");
      
      // Add debug logging setup if not already present
      if (!swiftContent.includes("Analytics.setAnalyticsCollectionEnabled")) {
        const debugSetup = `
    // Enable Firebase Analytics debug logging
    Analytics.setAnalyticsCollectionEnabled(true)
    print("FirebaseAnalyticsPlugin: Debug logging enabled")`;
        
        // Insert after pluginInitialize
        swiftContent = swiftContent.replace(
          /(override func pluginInitialize\(\) {[\s\S]*?})/,
          `$1${debugSetup}`
        );
        
        fs.writeFileSync(swiftFilePath, swiftContent);
        console.log("Firebase Analytics Plugin: Added debug logging setup to iOS");
      }
    }
  } catch (error) {
    console.log("Firebase Analytics Plugin: Could not add debug setup:", error.message);
  }

  console.log(
    "Firebase Analytics Plugin: iOS post-install hook completed successfully"
  );
};

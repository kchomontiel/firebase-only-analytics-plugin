#!/usr/bin/env node

/**
 * iOS Post-Install Hook for Firebase Analytics Plugin
 * Ensures GoogleService-Info.plist is properly copied to the iOS project
 */

const fs = require("fs");
const path = require("path");

module.exports = function (context) {
  const Q = context.requireCordovaModule("q");
  const deferral = Q.defer();

  console.log("Firebase Analytics Plugin: Running iOS post-install hook...");

  // Check if we're running on iOS platform
  if (context.opts.platforms.indexOf("ios") === -1) {
    console.log("Firebase Analytics Plugin: Not iOS platform, skipping hook");
    deferral.resolve();
    return deferral.promise;
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
    deferral.resolve();
    return deferral.promise;
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
    deferral.reject(error);
    return deferral.promise;
  }

  console.log(
    "Firebase Analytics Plugin: iOS post-install hook completed successfully"
  );
  deferral.resolve();

  return deferral.promise;
};

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
  
  // Debug logging for OutSystems builds
  console.log("Firebase Analytics Plugin: context.opts.projectRoot:", context.opts.projectRoot);
  console.log("Firebase Analytics Plugin: context.opts.platforms:", context.opts.platforms);

  // Check if we're running on iOS platform
  // For OutSystems builds, context.opts.platforms might not be set correctly
  // So we'll check if the ios platform directory exists instead
  const iosPlatformPath = path.join(context.opts.projectRoot, "platforms", "ios");
  console.log("Firebase Analytics Plugin: Checking iOS platform at:", iosPlatformPath);
  console.log("Firebase Analytics Plugin: iOS platform exists:", fs.existsSync(iosPlatformPath));
  
  if (!fs.existsSync(iosPlatformPath)) {
    console.log("Firebase Analytics Plugin: iOS platform not found, skipping hook");
    return;
  }
  
  console.log("Firebase Analytics Plugin: iOS platform found, continuing with hook execution");

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

  // Enable Firebase Analytics debug logging via environment variable in Info.plist
  try {
    const infoPlistPath = path.join(platformPath, "*.app", "Info.plist");
    const infoPlistFiles = fs
      .readdirSync(platformPath)
      .filter((file) => file.endsWith(".plist"));

    for (const plistFile of infoPlistFiles) {
      if (plistFile.includes("Info.plist")) {
        const plistPath = path.join(platformPath, plistFile);
        if (fs.existsSync(plistPath)) {
          let plistContent = fs.readFileSync(plistPath, "utf8");

          // Add FIRAnalyticsDebugEnabled environment variable if not present
          if (!plistContent.includes("FIRAnalyticsDebugEnabled")) {
            const debugEnvVar = `
    <key>LSEnvironment</key>
    <dict>
        <key>FIRAnalyticsDebugEnabled</key>
        <string>YES</string>
    </dict>`;

            // Insert before closing </dict> tag
            plistContent = plistContent.replace(
              /<\/dict>\s*<\/plist>/,
              `${debugEnvVar}
</dict>
</plist>`
            );

            fs.writeFileSync(plistPath, plistContent);
            console.log(
              "Firebase Analytics Plugin: Added FIRAnalyticsDebugEnabled to Info.plist"
            );
            break;
          }
        }
      }
    }
  } catch (error) {
    console.log(
      "Firebase Analytics Plugin: Could not add debug environment variable:",
      error.message
    );
  }

  console.log(
    "Firebase Analytics Plugin: iOS post-install hook completed successfully"
  );
};

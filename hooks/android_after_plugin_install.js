#!/usr/bin/env node

/**
 * Android Post-Install Hook for Firebase Analytics Plugin
 * Ensures Google Services plugin is properly configured in build.gradle
 */

const fs = require("fs");
const path = require("path");

module.exports = function (context) {
  const deferral = { resolve: () => {}, reject: () => {} };

  console.log(
    "Firebase Analytics Plugin: Running Android post-install hook..."
  );

  // Debug logging for OutSystems builds
  console.log(
    "Firebase Analytics Plugin: context.opts.projectRoot:",
    context.opts.projectRoot
  );
  console.log(
    "Firebase Analytics Plugin: context.opts.platforms:",
    context.opts.platforms
  );

  // Check if we're running on Android platform
  // For OutSystems builds, context.opts.platforms might not be set correctly
  // So we'll check if the android platform directory exists instead
  const androidPlatformPath = path.join(
    context.opts.projectRoot,
    "platforms",
    "android"
  );
  console.log(
    "Firebase Analytics Plugin: Checking Android platform at:",
    androidPlatformPath
  );
  console.log(
    "Firebase Analytics Plugin: Android platform exists:",
    fs.existsSync(androidPlatformPath)
  );

  if (!fs.existsSync(androidPlatformPath)) {
    console.log(
      "Firebase Analytics Plugin: Android platform not found, skipping hook"
    );
    return;
  }

  console.log(
    "Firebase Analytics Plugin: Android platform found, continuing with hook execution"
  );

  const platformPath = path.join(
    context.opts.projectRoot,
    "platforms",
    "android"
  );
  const buildGradlePath = path.join(platformPath, "build.gradle");
  const appBuildGradlePath = path.join(platformPath, "app", "build.gradle");
  const googleServicesSourcePath = path.join(
    context.opts.projectRoot,
    "google-services.json"
  );
  const googleServicesTargetPath = path.join(
    platformPath,
    "app",
    "google-services.json"
  );

  // Check if platform exists
  if (!fs.existsSync(platformPath)) {
    console.log(
      "Firebase Analytics Plugin: Android platform not found, skipping hook"
    );
    return;
  }

  try {
    // Configure root build.gradle
    if (fs.existsSync(buildGradlePath)) {
      let buildGradleContent = fs.readFileSync(buildGradlePath, "utf8");

      // Add Google Services classpath if not already present
      if (!buildGradleContent.includes("com.google.gms:google-services")) {
        const classpathRegex =
          /(classpath\s+['"]com\.android\.tools\.build:gradle:[^'"]*['"])/;
        if (classpathRegex.test(buildGradleContent)) {
          buildGradleContent = buildGradleContent.replace(
            classpathRegex,
            "$1\n        classpath 'com.google.gms:google-services:4.4.0'"
          );
          fs.writeFileSync(buildGradlePath, buildGradleContent);
          console.log(
            "Firebase Analytics Plugin: Added Google Services classpath to build.gradle"
          );
        } else {
          console.log(
            "Firebase Analytics Plugin: Warning - Could not find android gradle classpath to add Google Services classpath"
          );
        }
      } else {
        console.log(
          "Firebase Analytics Plugin: Google Services classpath already present"
        );
      }
    }

    // Configure app build.gradle
    if (fs.existsSync(appBuildGradlePath)) {
      let appBuildGradleContent = fs.readFileSync(appBuildGradlePath, "utf8");

      // Add Google Services plugin if not already present
      if (!appBuildGradleContent.includes("com.google.gms.google-services")) {
        // Add Google Services plugin after android application plugin
        const pluginsRegex =
          /(apply plugin: ['"]com\.android\.application['"])/;
        if (pluginsRegex.test(appBuildGradleContent)) {
          appBuildGradleContent = appBuildGradleContent.replace(
            pluginsRegex,
            "$1\napply plugin: 'com.google.gms.google-services'"
          );
          fs.writeFileSync(appBuildGradlePath, appBuildGradleContent);
          console.log(
            "Firebase Analytics Plugin: Added Google Services plugin to app/build.gradle"
          );
        } else {
          console.log(
            "Firebase Analytics Plugin: Warning - Could not find android application plugin to add Google Services plugin"
          );
        }
      } else {
        console.log(
          "Firebase Analytics Plugin: Google Services plugin already present"
        );
      }

      // Add JNA conflict resolution directly to build.gradle
      let configAdded = false;

      // Check if packaging configuration is already present
      if (!appBuildGradleContent.includes("packagingOptions")) {
        const packagingConfig = `
    packagingOptions {
        pickFirst 'META-INF/AL2.0'
        pickFirst 'META-INF/LGPL2.1'
        pickFirst 'META-INF/DEPENDENCIES'
        pickFirst 'META-INF/LICENSE'
        pickFirst 'META-INF/LICENSE.txt'
        pickFirst 'META-INF/NOTICE'
        pickFirst 'META-INF/NOTICE.txt'
    }`;

        // Try multiple approaches to add the configuration
        const androidBlockRegex = /(android\s*\{[^}]*?)(\n\s*\})/s;
        if (androidBlockRegex.test(appBuildGradleContent)) {
          appBuildGradleContent = appBuildGradleContent.replace(
            androidBlockRegex,
            `$1${packagingConfig}\n    $2`
          );
          configAdded = true;
        } else {
          // Alternative: add before the closing brace of android block
          const androidAltRegex = /(android\s*\{[^}]*)(\})/s;
          if (androidAltRegex.test(appBuildGradleContent)) {
            appBuildGradleContent = appBuildGradleContent.replace(
              androidAltRegex,
              `$1${packagingConfig}\n    $2`
            );
            configAdded = true;
          }
        }

        if (configAdded) {
          fs.writeFileSync(appBuildGradlePath, appBuildGradleContent);
          console.log(
            "Firebase Analytics Plugin: Added packaging configuration to resolve JNA conflicts"
          );
        } else {
          console.log(
            "Firebase Analytics Plugin: Warning - Could not find android block in build.gradle"
          );
        }
      } else {
        console.log(
          "Firebase Analytics Plugin: Packaging configuration already present"
        );
      }

      // Add configurations exclusion for JNA
      if (!appBuildGradleContent.includes("configurations.all")) {
        const configurationsConfig = `
configurations.all {
    exclude group: 'net.java.dev.jna', module: 'jna'
    exclude group: 'net.java.dev.jna', module: 'jna-platform'
}`;

        // Add at the end of the file before any closing braces
        appBuildGradleContent = appBuildGradleContent.replace(
          /(\s*)(}\s*$)/m,
          `$1${configurationsConfig}\n$1$2`
        );

        fs.writeFileSync(appBuildGradlePath, appBuildGradleContent);
        console.log(
          "Firebase Analytics Plugin: Added configurations exclusion for JNA conflicts"
        );
      } else {
        console.log(
          "Firebase Analytics Plugin: Configurations exclusion already present"
        );
      }

      // Note: The main configuration is now handled by build.gradle framework via gradleReference
      // This hook section is kept as fallback for additional configurations if needed
      console.log(
        "Firebase Analytics Plugin: Main configuration handled by build.gradle framework"
      );

      // Note: JNA conflict resolution is now handled by the build.gradle framework
      // which is automatically included via gradleReference in plugin.xml
      console.log(
        "Firebase Analytics Plugin: JNA conflict resolution handled by build.gradle framework"
      );
    }

    // Copy google-services.json to the correct location
    if (fs.existsSync(googleServicesSourcePath)) {
      // Ensure the app directory exists
      const appDir = path.dirname(googleServicesTargetPath);
      if (!fs.existsSync(appDir)) {
        fs.mkdirSync(appDir, { recursive: true });
      }

      // Copy the file
      fs.copyFileSync(googleServicesSourcePath, googleServicesTargetPath);
      console.log(
        "Firebase Analytics Plugin: Copied google-services.json to platforms/android/app/"
      );
    } else {
      console.log(
        "Firebase Analytics Plugin: google-services.json not found in project root"
      );
    }

    console.log(
      "Firebase Analytics Plugin: Android post-install hook completed successfully"
    );
  } catch (error) {
    console.error(
      "Firebase Analytics Plugin: Error in Android post-install hook:",
      error.message
    );
  }
};

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

  // Check if we're running on Android platform
  if (
    !context.opts.platforms ||
    context.opts.platforms.indexOf("android") === -1
  ) {
    console.log(
      "Firebase Analytics Plugin: Not Android platform, skipping hook"
    );
    return;
  }

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
        // Find the plugins section and add Google Services plugin
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
        }
      } else {
        console.log(
          "Firebase Analytics Plugin: Google Services plugin already present"
        );
      }

      // Add packaging configuration to resolve JNA conflicts
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
        exclude 'META-INF/AL2.0'
        exclude 'META-INF/LGPL2.1'
    }`;
        
        // Find the android block and insert packagingOptions before its closing brace
        const androidBlockRegex = /(android\s*\{[^}]*)(\})/s;
        if (androidBlockRegex.test(appBuildGradleContent)) {
          appBuildGradleContent = appBuildGradleContent.replace(
            androidBlockRegex,
            `$1${packagingConfig}\n    $2`
          );
          
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

      // Alternative solution: Apply Firebase Analytics Gradle configuration
      const firebaseGradleConfigPath = path.join(
        platformPath,
        "app",
        "firebase-analytics.gradle"
      );
      const pluginGradleConfigPath = path.join(
        context.opts.projectRoot,
        "plugins",
        "cordova-plugin-firebase-analytics",
        "src",
        "android",
        "firebase-analytics.gradle"
      );

      // Copy the Firebase Analytics Gradle configuration
      if (fs.existsSync(pluginGradleConfigPath)) {
        fs.copyFileSync(pluginGradleConfigPath, firebaseGradleConfigPath);
        console.log(
          "Firebase Analytics Plugin: Copied firebase-analytics.gradle configuration"
        );
      }

      // Apply the Firebase Analytics configuration to build.gradle
      if (!appBuildGradleContent.includes("apply from: 'firebase-analytics.gradle'")) {
        const applyConfig = `apply from: 'firebase-analytics.gradle'`;
        
        // Add after the plugins section
        const pluginsRegex = /(apply plugin: ['"]com\.android\.application['"])/;
        if (pluginsRegex.test(appBuildGradleContent)) {
          appBuildGradleContent = appBuildGradleContent.replace(
            pluginsRegex,
            `$1\n${applyConfig}`
          );
          
          fs.writeFileSync(appBuildGradlePath, appBuildGradleContent);
          console.log(
            "Firebase Analytics Plugin: Applied firebase-analytics.gradle to build.gradle"
          );
        }
      } else {
        console.log(
          "Firebase Analytics Plugin: Firebase Analytics Gradle configuration already applied"
        );
      }
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

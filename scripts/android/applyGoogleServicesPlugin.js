#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

module.exports = function(context) {
    console.log("🔧 FirebasePlugin: Applying Google Services plugin to build.gradle files...");
    
    const projectRoot = context.opts.projectRoot;
    const platformAndroidDir = path.join(projectRoot, "platforms", "android");
    const rootBuildGradlePath = path.join(platformAndroidDir, "build.gradle");
    const appBuildGradlePath = path.join(platformAndroidDir, "app", "build.gradle");

    try {
        // Apply to root build.gradle first
        if (fs.existsSync(rootBuildGradlePath)) {
            console.log("🔧 FirebasePlugin: Checking root build.gradle...");
            let rootBuildGradleContent = fs.readFileSync(rootBuildGradlePath, 'utf8');
            
            // Check if classpath is already added
            if (!rootBuildGradleContent.includes("classpath 'com.google.gms:google-services:")) {
                // Add classpath to dependencies block
                rootBuildGradleContent = rootBuildGradleContent.replace(
                    /(dependencies\s*\{)/,
                    "$1\n        classpath 'com.google.gms:google-services:4.4.2'"
                );
                fs.writeFileSync(rootBuildGradlePath, rootBuildGradleContent, 'utf8');
                console.log("✅ FirebasePlugin: Added Google Services classpath to root build.gradle");
            } else {
                console.log("✅ FirebasePlugin: Google Services classpath already exists in root build.gradle");
            }
        }

        // Apply to app build.gradle
        if (fs.existsSync(appBuildGradlePath)) {
            console.log("🔧 FirebasePlugin: Checking app build.gradle...");
            let appBuildGradleContent = fs.readFileSync(appBuildGradlePath, 'utf8');
            
            // Check if the plugin is already applied
            if (!appBuildGradleContent.includes("apply plugin: 'com.google.gms.google-services'")) {
                // Add the plugin at the end of the file
                appBuildGradleContent = appBuildGradleContent + "\n\n// Apply Google Services plugin for Firebase\napply plugin: 'com.google.gms.google-services'\n";
                fs.writeFileSync(appBuildGradlePath, appBuildGradleContent, 'utf8');
                console.log("✅ FirebasePlugin: Applied Google Services plugin to app/build.gradle");
            } else {
                console.log("✅ FirebasePlugin: Google Services plugin already applied to app/build.gradle");
            }
        } else {
            console.error("❌ FirebasePlugin: app/build.gradle not found: " + appBuildGradlePath);
            return;
        }
        
        console.log("🎉 FirebasePlugin: Google Services plugin configuration completed successfully!");

    } catch (err) {
        console.error("❌ FirebasePlugin: Error applying Google Services plugin: " + err.message);
    }
};

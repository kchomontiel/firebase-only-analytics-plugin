#!/usr/bin/env node

var fs = require('fs');
var path = require('path');
var rootdir = process.argv[2];

var platformAndroidDir = path.join(rootdir, "platforms", "android");
var appBuildGradlePath = path.join(platformAndroidDir, "app", "build.gradle");

console.log("🔧 FirebasePlugin: Applying Google Services plugin to app build.gradle...");

try {
    if (!fs.existsSync(appBuildGradlePath)) {
        console.error("❌ FirebasePlugin: app/build.gradle not found: " + appBuildGradlePath);
        process.exit(1);
    }

    // Read the current build.gradle file
    var buildGradleContent = fs.readFileSync(appBuildGradlePath, 'utf8');
    
    // Check if the plugin is already applied
    if (buildGradleContent.includes("apply plugin: 'com.google.gms.google-services'")) {
        console.log("✅ FirebasePlugin: Google Services plugin already applied");
        return;
    }
    
    // Add the plugin at the end of the file
    var updatedContent = buildGradleContent + "\n\n// Apply Google Services plugin for Firebase\napply plugin: 'com.google.gms.google-services'\n";
    
    // Write the updated content back to the file
    fs.writeFileSync(appBuildGradlePath, updatedContent, 'utf8');
    
    console.log("✅ FirebasePlugin: Google Services plugin applied successfully to app/build.gradle");
    console.log("🎉 FirebasePlugin: Configuration setup completed successfully!");

} catch (err) {
    console.error("❌ FirebasePlugin: Error applying Google Services plugin: " + err.message);
    process.exit(1);
}

#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

module.exports = function(context) {
    console.log("🔧 FirebasePlugin: Manually copying google-services.json to correct location...");
    
    const projectRoot = context.opts.projectRoot;
    const platformAndroidDir = path.join(projectRoot, "platforms", "android");
    const appDir = path.join(platformAndroidDir, "app");
    
    // Source file (from plugin root)
    const sourceFile = path.join(context.opts.plugin.dir, "google-services.json");
    
    // Destination files
    const destFile1 = path.join(appDir, "google-services.json");
    const destFile2 = path.join(platformAndroidDir, "google-services.json");
    
    try {
        // Check if source file exists
        if (!fs.existsSync(sourceFile)) {
            console.error("❌ FirebasePlugin: google-services.json not found in plugin root: " + sourceFile);
            return;
        }
        
        // Copy to app directory
        if (fs.existsSync(appDir)) {
            fs.copyFileSync(sourceFile, destFile1);
            console.log("✅ FirebasePlugin: Copied google-services.json to: " + destFile1);
        } else {
            console.error("❌ FirebasePlugin: app directory not found: " + appDir);
        }
        
        // Copy to platform root
        if (fs.existsSync(platformAndroidDir)) {
            fs.copyFileSync(sourceFile, destFile2);
            console.log("✅ FirebasePlugin: Copied google-services.json to: " + destFile2);
        } else {
            console.error("❌ FirebasePlugin: platform directory not found: " + platformAndroidDir);
        }
        
        console.log("🎉 FirebasePlugin: google-services.json copied successfully!");
        
    } catch (err) {
        console.error("❌ FirebasePlugin: Error copying google-services.json: " + err.message);
    }
};

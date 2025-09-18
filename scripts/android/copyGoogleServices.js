#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

module.exports = function(context) {
    console.log('📋 FirebasePlugin: Copying google-services.json to app directory...');
    
    const projectRoot = context.opts.projectRoot;
    const platformRoot = path.join(projectRoot, 'platforms', 'android');
    const appDir = path.join(platformRoot, 'app');
    const googleServicesSource = path.join(projectRoot, 'google-services.json');
    const googleServicesTarget = path.join(appDir, 'google-services.json');
    
    // Ensure app directory exists
    if (!fs.existsSync(appDir)) {
        fs.mkdirSync(appDir, { recursive: true });
        console.log('📁 FirebasePlugin: Created app directory');
    }
    
    // Copy google-services.json to app directory
    if (fs.existsSync(googleServicesSource)) {
        fs.copyFileSync(googleServicesSource, googleServicesTarget);
        console.log('✅ FirebasePlugin: google-services.json copied to app directory');
    } else {
        console.log('❌ FirebasePlugin: google-services.json not found in project root');
    }
    
    // Also copy to platform root for compatibility
    const platformTarget = path.join(platformRoot, 'google-services.json');
    if (fs.existsSync(googleServicesSource)) {
        fs.copyFileSync(googleServicesSource, platformTarget);
        console.log('✅ FirebasePlugin: google-services.json copied to platform root');
    }
};

#!/usr/bin/env node

/**
 * Hook script to fix iOS deployment targets for all targets in the project
 * This ensures compatibility with modern iOS versions (12.0+)
 */

var fs = require('fs');
var path = require('path');

module.exports = function(context) {
    var Q = context.requireCordovaModule('q');
    var deferral = Q.defer();

    // Only run for iOS platform
    if (context.opts.platforms.indexOf('ios') === -1) {
        deferral.resolve();
        return deferral.promise;
    }

    console.log('FirebasePlugin: Fixing iOS deployment targets...');

    try {
        // Path to the iOS project
        var iosProjectPath = path.join(context.opts.projectRoot, 'platforms', 'ios');
        
        if (!fs.existsSync(iosProjectPath)) {
            console.log('FirebasePlugin: iOS platform not found, skipping deployment target fix');
            deferral.resolve();
            return deferral.promise;
        }

        // Fix Podfile
        fixPodfile(iosProjectPath);
        
        // Fix project.pbxproj files
        fixProjectFiles(iosProjectPath);

        console.log('FirebasePlugin: iOS deployment targets fixed successfully');
        deferral.resolve();

    } catch (error) {
        console.error('FirebasePlugin: Error fixing deployment targets:', error);
        deferral.reject(error);
    }

    return deferral.promise;
};

function fixPodfile(iosProjectPath) {
    var podfilePath = path.join(iosProjectPath, 'Podfile');
    
    if (!fs.existsSync(podfilePath)) {
        console.log('FirebasePlugin: Podfile not found, skipping');
        return;
    }

    var podfileContent = fs.readFileSync(podfilePath, 'utf8');
    
    // Add post_install script if not present
    if (!podfileContent.includes('post_install')) {
        var postInstallScript = `
post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      # Force deployment target to 12.0 for all targets
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '12.0'
      
      # Set Swift optimization level for FirebasePlugin
      if target.name == 'FirebasePlugin'
        config.build_settings['SWIFT_OPTIMIZATION_LEVEL'] = '-Onone'
      end
    end
  end
end
`;
        
        podfileContent += postInstallScript;
        fs.writeFileSync(podfilePath, podfileContent);
        console.log('FirebasePlugin: Added post_install script to Podfile');
    }
}

function fixProjectFiles(iosProjectPath) {
    // Find all .xcodeproj directories
    var projectDirs = fs.readdirSync(iosProjectPath).filter(function(dir) {
        return dir.endsWith('.xcodeproj') && fs.statSync(path.join(iosProjectPath, dir)).isDirectory();
    });

    projectDirs.forEach(function(projectDir) {
        var projectPath = path.join(iosProjectPath, projectDir, 'project.pbxproj');
        
        if (fs.existsSync(projectPath)) {
            fixProjectPbxproj(projectPath);
        }
    });
}

function fixProjectPbxproj(projectPath) {
    var content = fs.readFileSync(projectPath, 'utf8');
    var modified = false;

    // Fix deployment target settings
    var deploymentTargetRegex = /IPHONEOS_DEPLOYMENT_TARGET = [0-9.]+;/g;
    var matches = content.match(deploymentTargetRegex);
    
    if (matches) {
        matches.forEach(function(match) {
            var oldValue = match;
            var newValue = 'IPHONEOS_DEPLOYMENT_TARGET = 12.0;';
            
            if (oldValue !== newValue) {
                content = content.replace(oldValue, newValue);
                modified = true;
                console.log('FirebasePlugin: Updated deployment target from', oldValue, 'to', newValue);
            }
        });
    }

    if (modified) {
        fs.writeFileSync(projectPath, content);
        console.log('FirebasePlugin: Updated project.pbxproj deployment targets');
    }
}

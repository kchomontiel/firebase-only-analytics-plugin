"use strict";

var path = require("path");
var AdmZip = require("adm-zip");

var utils = require("../utilities");

var constants = {
  googleServices: "google-services",
};

module.exports = function (context) {
  var cordovaAbove8 = utils.isCordovaAbove(context, 8);
  var cordovaAbove7 = utils.isCordovaAbove(context, 7);
  var defer;
  if (cordovaAbove8) {
    defer = require("q").defer();
  } else {
    defer = context.requireCordovaModule("q").defer();
  }

  var platform = context.opts.plugin.platform;
  var platformConfig = utils.getPlatformConfigs(platform);
  if (!platformConfig) {
    utils.handleError("Invalid platform", defer);
  }

  var wwwPath = utils.getResourcesFolderPath(context, platform, platformConfig);
  var sourceFolderPath = utils.getSourceFolderPath(context, wwwPath);

  console.log(
    "🔍 FirebasePlugin: Looking for google-services.zip in:",
    sourceFolderPath
  );

  var googleServicesZipFile = utils.getZipFile(
    sourceFolderPath,
    constants.googleServices
  );
  if (!googleServicesZipFile) {
    console.log(
      "⚠️  No zip file found containing google services configuration file"
    );
    console.log("📁 Searched in:", sourceFolderPath);
    console.log(
      "🔧 Please ensure google-services.zip is placed in one of these locations:"
    );
    console.log(
      "   - www/" + utils.getAppId(context) + ".firebase/google-services.zip"
    );
    console.log(
      "   - www/firebase." + utils.getAppId(context) + "/google-services.zip"
    );
    utils.handleError(
      "No zip file found containing google services configuration file",
      defer
    );
  }

  console.log(
    "✅ FirebasePlugin: Found google-services.zip:",
    googleServicesZipFile
  );

  var zip = new AdmZip(googleServicesZipFile);

  var targetPath = path.join(wwwPath, constants.googleServices);
  console.log("📦 FirebasePlugin: Extracting to:", targetPath);
  zip.extractAllTo(targetPath, true);

  var files = utils.getFilesFromPath(targetPath);
  if (!files) {
    console.log("❌ FirebasePlugin: No files found in extracted directory");
    utils.handleError("No directory found", defer);
  }

  var fileName = files.find(function (name) {
    return name.endsWith(platformConfig.firebaseFileExtension);
  });
  if (!fileName) {
    console.log(
      "❌ FirebasePlugin: No file found with extension:",
      platformConfig.firebaseFileExtension
    );
    utils.handleError("No file found", defer);
  }

  console.log("✅ FirebasePlugin: Found configuration file:", fileName);

  var sourceFilePath = path.join(targetPath, fileName);
  var destFilePath = path.join(context.opts.plugin.dir, fileName);

  console.log("📋 FirebasePlugin: Copying to plugin directory:", destFilePath);
  utils.copyFromSourceToDestPath(defer, sourceFilePath, destFilePath);

  if (cordovaAbove7) {
    // Copy to platforms/android/app/ (for newer Android projects)
    var destPath = path.join(
      context.opts.projectRoot,
      "platforms",
      platform,
      "app"
    );
    console.log(
      "📱 FirebasePlugin: Copying to platform app directory:",
      destPath
    );

    if (utils.checkIfFolderExists(destPath)) {
      var destFilePath = path.join(destPath, fileName);
      console.log(
        "✅ FirebasePlugin: Platform app directory exists, copying to:",
        destFilePath
      );
      utils.copyFromSourceToDestPath(defer, sourceFilePath, destFilePath);
    } else {
      // Create the directory if it doesn't exist
      console.log(
        "📁 FirebasePlugin: Creating platform app directory:",
        destPath
      );
      utils.createOrCheckIfFolderExists(destPath);
      var destFilePath = path.join(destPath, fileName);
      console.log(
        "📋 FirebasePlugin: Copying to created app directory:",
        destFilePath
      );
      utils.copyFromSourceToDestPath(defer, sourceFilePath, destFilePath);
    }

    // Also copy to platforms/android/ (for Firebase to find it)
    var rootDestPath = path.join(
      context.opts.projectRoot,
      "platforms",
      platform
    );
    var rootDestFilePath = path.join(rootDestPath, fileName);
    console.log(
      "📋 FirebasePlugin: Also copying to platform root:",
      rootDestFilePath
    );
    utils.copyFromSourceToDestPath(defer, sourceFilePath, rootDestFilePath);
  }

  console.log("🎉 FirebasePlugin: Configuration setup completed successfully!");

  return defer.promise;
};

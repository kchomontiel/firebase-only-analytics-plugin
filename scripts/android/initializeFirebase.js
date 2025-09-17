#!/usr/bin/env node

var fs = require("fs");
var path = require("path");
var Q = require("q");

module.exports = function (context) {
  var deferral = Q.defer();

  // ✅ CRITICAL FIX: Defensive platform detection
  var platform = null;
  if (
    context.opts &&
    context.opts.platforms &&
    context.opts.platforms.length > 0
  ) {
    platform = context.opts.platforms[0];
  } else if (
    context.opts &&
    context.opts.cordova &&
    context.opts.cordova.platforms &&
    context.opts.cordova.platforms.length > 0
  ) {
    platform = context.opts.cordova.platforms[0];
  } else {
    console.log(
      "FirebasePlugin: No platform detected, skipping Firebase initialization"
    );
    deferral.resolve();
    return deferral.promise;
  }

  console.log("FirebasePlugin: Detected platform:", platform);

  if (platform === "android") {
    console.log(
      "FirebasePlugin: Running initializeFirebase.js hook for Android..."
    );

    var androidProjectPath = path.join(
      context.opts.projectRoot,
      "platforms",
      "android"
    );
    var mainActivityPath = path.join(
      androidProjectPath,
      "app",
      "src",
      "main",
      "java"
    );

    // Find MainActivity.java
    var mainActivityFile = null;
    if (fs.existsSync(mainActivityPath)) {
      var files = fs.readdirSync(mainActivityPath, { recursive: true });
      for (var file of files) {
        if (file.endsWith("MainActivity.java")) {
          mainActivityFile = path.join(mainActivityPath, file);
          break;
        }
      }
    }

    if (mainActivityFile && fs.existsSync(mainActivityFile)) {
      console.log(
        "FirebasePlugin: Found MainActivity.java at:",
        mainActivityFile
      );

      var content = fs.readFileSync(mainActivityFile, "utf8");

      // Check if Firebase initialization is already present
      if (content.includes("FirebaseApp.initializeApp(this)")) {
        console.log(
          "FirebasePlugin: Firebase initialization already present in MainActivity.java"
        );
        deferral.resolve();
        return deferral.promise;
      }

      // Add Firebase import
      if (!content.includes("import com.google.firebase.FirebaseApp;")) {
        var importIndex = content.indexOf(
          "import org.apache.cordova.CordovaActivity;"
        );
        if (importIndex !== -1) {
          content =
            content.substring(0, importIndex) +
            "import com.google.firebase.FirebaseApp;\n" +
            content.substring(importIndex);
          console.log(
            "FirebasePlugin: Added Firebase import to MainActivity.java"
          );
        } else {
          // Fallback: add import after package declaration
          var packageIndex = content.indexOf("package ");
          if (packageIndex !== -1) {
            var endOfPackage = content.indexOf(";", packageIndex) + 1;
            var newlineAfterPackage = content.indexOf("\n", endOfPackage) + 1;
            content =
              content.substring(0, newlineAfterPackage) +
              "import com.google.firebase.FirebaseApp;\n" +
              content.substring(newlineAfterPackage);
            console.log(
              "FirebasePlugin: Added Firebase import after package declaration"
            );
          }
        }
      }

      // Add Firebase initialization in onCreate
      if (!content.includes("FirebaseApp.initializeApp(this)")) {
        var onCreateIndex = content.indexOf(
          "super.onCreate(savedInstanceState);"
        );
        if (onCreateIndex !== -1) {
          var insertPoint = content.indexOf("\n", onCreateIndex) + 1;
          content =
            content.substring(0, insertPoint) +
            "        // Initialize Firebase\n" +
            "        try {\n" +
            "            FirebaseApp.initializeApp(this);\n" +
            '            android.util.Log.d("FirebasePlugin", "Firebase initialized in MainActivity");\n' +
            "        } catch (Exception e) {\n" +
            '            android.util.Log.e("FirebasePlugin", "Failed to initialize Firebase: " + e.getMessage());\n' +
            "        }\n" +
            content.substring(insertPoint);
        }
      }

      fs.writeFileSync(mainActivityFile, content, "utf8");
      console.log(
        "FirebasePlugin: Firebase initialization added to MainActivity.java"
      );
    } else {
      console.log(
        "FirebasePlugin: MainActivity.java not found, skipping Firebase initialization"
      );
    }

    // ✅ CRITICAL FIX: Configure custom Application class in AndroidManifest.xml
    var androidManifestPath = path.join(androidProjectPath, "app", "src", "main", "AndroidManifest.xml");
    if (fs.existsSync(androidManifestPath)) {
      console.log("FirebasePlugin: Configuring custom Application class in AndroidManifest.xml");
      
      var manifestContent = fs.readFileSync(androidManifestPath, "utf8");
      
      // Check if custom Application class is already configured
      if (manifestContent.includes('android:name="org.apache.cordova.firebase.FirebaseApplication"')) {
        console.log("FirebasePlugin: Custom Application class already configured in AndroidManifest.xml");
      } else {
        // Find the application tag and add the custom class
        var applicationRegex = /<application([^>]*)>/;
        if (applicationRegex.test(manifestContent)) {
          manifestContent = manifestContent.replace(applicationRegex, function(match, attributes) {
            // Check if android:name is already present
            if (attributes.includes('android:name=')) {
              // Replace existing android:name
              return match.replace(/android:name="[^"]*"/, 'android:name="org.apache.cordova.firebase.FirebaseApplication"');
            } else {
              // Add android:name attribute
              return '<application' + attributes + ' android:name="org.apache.cordova.firebase.FirebaseApplication">';
            }
          });
          
          fs.writeFileSync(androidManifestPath, manifestContent, "utf8");
          console.log("FirebasePlugin: Custom Application class configured in AndroidManifest.xml");
        } else {
          console.log("FirebasePlugin: No application tag found in AndroidManifest.xml");
        }
      }
    } else {
      console.log("FirebasePlugin: AndroidManifest.xml not found, skipping Application class configuration");
    }
  }

  deferral.resolve();
  return deferral.promise;
};

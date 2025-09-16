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
  }

  deferral.resolve();
  return deferral.promise;
};

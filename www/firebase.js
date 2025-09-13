var exec = require('cordova/exec');

var PLUGIN_NAME = 'FirebasePlugin';

//
// Cloud Messaging FCM - Placeholder implementations for OutSystems compatibility
//
exports.getId = function (success, error) {
  // Return a placeholder ID for OutSystems compatibility
  if (success) success("firebase_installation_id_placeholder");
};

exports.getToken = function (success, error) {
  // Return a placeholder token for OutSystems compatibility
  if (success) success("firebase_token_placeholder");
};

exports.hasPermission = function (success, error) {
  // Return true for OutSystems compatibility
  if (success) success({isEnabled: true});
};

exports.grantPermission = function (success, error) {
  // Return success for OutSystems compatibility
  if (success) success();
};

exports.setBadgeNumber = function (number, success, error) {
  // Placeholder implementation for OutSystems compatibility
  if (success) success();
};

exports.getBadgeNumber = function (success, error) {
  // Return 0 for OutSystems compatibility
  if (success) success(0);
};

exports.subscribe = function (topic, success, error) {
  // Placeholder implementation for OutSystems compatibility
  console.log("FirebasePlugin - Subscribing to topic:", topic);
  if (success) success();
};

exports.unsubscribe = function (topic, success, error) {
  // Placeholder implementation for OutSystems compatibility
  console.log("FirebasePlugin - Unsubscribing from topic:", topic);
  if (success) success();
};

exports.unregister = function (success, error) {
  // Placeholder implementation for OutSystems compatibility
  console.log("FirebasePlugin - Unregistering from Firebase");
  if (success) success();
};

exports.onNotificationOpen = function (success, error) {
  // Placeholder implementation for OutSystems compatibility
  if (success) success();
};

exports.onTokenRefresh = function (success, error) {
  // Placeholder implementation for OutSystems compatibility
  if (success) success("firebase_token_refresh_placeholder");
};

exports.clearAllNotifications = function (success, error) {
  // Placeholder implementation for OutSystems compatibility
  if (success) success();
};

//
// Analytics - Placeholder implementations for GTM/Analytics
//
exports.logEvent = function (name, params, success, error) {
  // Placeholder implementation for OutSystems compatibility
  console.log("FirebasePlugin - Logging event:", name, params);
  if (success) success();
};

exports.setScreenName = function (name, success, error) {
  // Placeholder implementation for OutSystems compatibility
  console.log("FirebasePlugin - Setting screen name:", name);
  if (success) success();
};

exports.setUserId = function (id, success, error) {
  // Placeholder implementation for OutSystems compatibility
  console.log("FirebasePlugin - Setting user ID:", id);
  if (success) success();
};

exports.setUserProperty = function (name, value, success, error) {
  // Placeholder implementation for OutSystems compatibility
  console.log("FirebasePlugin - Setting user property:", name, "=", value);
  if (success) success();
};

exports.setAnalyticsCollectionEnabled = function (enabled, success, error) {
  // Placeholder implementation for OutSystems compatibility
  console.log("FirebasePlugin - Setting analytics collection enabled:", enabled);
  if (success) success();
};

//
// Dynamic Links - Placeholder implementations
//
exports.onDynamicLink = function (success, error) {
  // Placeholder implementation for OutSystems compatibility
  if (success) success();
};

exports.getDynamicLink = function (success, error) {
  // Placeholder implementation for OutSystems compatibility
  if (success) success();
};

exports.dynamicLinkCallback = function (dynamicLink) {
  // Placeholder implementation for OutSystems compatibility
  var ev = document.createEvent('HTMLEvents');
  ev.dynamicLink = dynamicLink;
  ev.initEvent('dynamic-link', true, true, arguments);
  document.dispatchEvent(ev);
};

//
// Note: This plugin now provides only JavaScript interface for OutSystems MABS 11.1
// All methods return success to maintain compatibility with existing code
// Firebase functionality should be handled by OutSystems native capabilities
//
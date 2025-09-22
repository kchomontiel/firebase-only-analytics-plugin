# Cordova Firebase Analytics Plugin

Un plugin de Cordova para Firebase Analytics con soporte completo para iOS Privacy Manifest, implementado en Swift para iOS y Java para Android.

## Características

- ✅ **Método logEvent expuesto en JavaScript**
- ✅ **iOS implementado en Swift** (últimas versiones de Firebase)
- ✅ **Android implementado en Java** (últimas versiones de Firebase)
- ✅ **iOS Privacy Manifest automático** (incluido en Firebase SDK)
- ✅ **Soporte para Firebase Analytics 10.25.0+**
- ✅ **Métodos adicionales**: setUserProperty, setUserId, setAnalyticsCollectionEnabled, resetAnalyticsData

## Requisitos

- Cordova >= 7.0.0
- Cordova Android >= 6.0.0
- Cordova iOS >= 4.0.0
- Android API Level >= 21
- iOS >= 11.0

## Instalación

### 1. Instalar el plugin

```bash
cordova plugin add cordova-plugin-firebase-analytics
```

### 2. Configurar Firebase

#### Android

1. Descarga `google-services.json` desde Firebase Console
2. Coloca el archivo en la raíz de tu proyecto Cordova (junto a `config.xml`)
3. **El plugin copia automáticamente** el archivo a `platforms/android/app/google-services.json`
4. **El plugin configura automáticamente Google Services** para procesar el archivo

#### iOS

1. Descarga `GoogleService-Info.plist` desde Firebase Console
2. Coloca el archivo en la raíz de tu proyecto Cordova (junto a `config.xml`)
3. **El plugin copia automáticamente** el archivo a `platforms/ios/GoogleService-Info.plist`

### 3. Reconstruir la aplicación

```bash
cordova platform remove android
cordova platform remove ios
cordova platform add android
cordova platform add ios
cordova build
```

## Uso

### JavaScript API

#### Forma 1: Usando cordova.plugins.firebase.analytics

```javascript
// Logear un evento personalizado
cordova.plugins.firebase.analytics.logEvent("custom_event", {
  parameter_name: "parameter_value",
  score: 100,
});

// Logear un evento sin parámetros
cordova.plugins.firebase.analytics.logEvent("simple_event");

// Establecer propiedad de usuario
cordova.plugins.firebase.analytics.setUserProperty("favorite_color", "blue");

// Establecer ID de usuario
cordova.plugins.firebase.analytics.setUserId("user123");

// Habilitar/deshabilitar recolección de analytics
cordova.plugins.firebase.analytics.setAnalyticsCollectionEnabled(true);

// Resetear datos de analytics
cordova.plugins.firebase.analytics.resetAnalyticsData();
```

#### Forma 2: Usando window.fp (compatible con código existente)

```javascript
// Verificar inicialización primero
window.fp.isFirebaseInitialized(
  function (isInit) {
    if (isInit) {
      // Firebase está listo, enviar evento
      window.fp.logEvent(
        "custom_event",
        {
          parameter_name: "parameter_value",
          score: 100,
        },
        success,
        error
      );

       // Establecer nombre de pantalla
       window.fp.setScreenName("HomeScreen", success, error);
       
       // Verificar permisos de analytics
       window.fp.hasPermission(function(hasPermission) {
         console.log("Has analytics permission:", hasPermission);
       }, error);
     } else {
       console.log("Firebase not initialized");
     }
   },
   function (err) {
     console.log("Error checking Firebase initialization: " + err);
   }
 );

function success() {
  console.log("Operation completed successfully");
}

function error(err) {
  console.log("Error: " + err);
}
```

### Ejemplo completo

```javascript
document.addEventListener(
  "deviceready",
  function () {
    // Logear evento de inicio de sesión
    cordova.plugins.firebase.analytics.logEvent("login", {
      method: "email",
      user_type: "premium",
    });

    // Establecer propiedades del usuario
    cordova.plugins.firebase.analytics.setUserProperty(
      "subscription_type",
      "premium"
    );
    cordova.plugins.firebase.analytics.setUserId("user_12345");

    // Logear evento de compra
    cordova.plugins.firebase.analytics.logEvent("purchase", {
      transaction_id: "T12345",
      value: 29.99,
      currency: "USD",
      items: 2,
    });
  },
  false
);
```

## Métodos disponibles

### `logEvent(eventName, parameters, successCallback, errorCallback)`

Registra un evento personalizado en Firebase Analytics.

- **eventName** (string): Nombre del evento
- **parameters** (object, opcional): Parámetros del evento
- **successCallback** (function, opcional): Callback de éxito
- **errorCallback** (function, opcional): Callback de error

### `setUserProperty(name, value, successCallback, errorCallback)`

Establece una propiedad de usuario.

- **name** (string): Nombre de la propiedad
- **value** (string): Valor de la propiedad
- **successCallback** (function, opcional): Callback de éxito
- **errorCallback** (function, opcional): Callback de error

### `setUserId(userId, successCallback, errorCallback)`

Establece el ID del usuario.

- **userId** (string): ID del usuario
- **successCallback** (function, opcional): Callback de éxito
- **errorCallback** (function, opcional): Callback de error

### `setAnalyticsCollectionEnabled(enabled, successCallback, errorCallback)`

Habilita o deshabilita la recolección de analytics.

- **enabled** (boolean): true para habilitar, false para deshabilitar
- **successCallback** (function, opcional): Callback de éxito
- **errorCallback** (function, opcional): Callback de error

### `resetAnalyticsData(successCallback, errorCallback)`

Resetea los datos de analytics del usuario.

- **successCallback** (function, opcional): Callback de éxito
- **errorCallback** (function, opcional): Callback de error

### `isFirebaseInitialized(successCallback, errorCallback)`

Verifica si Firebase Analytics está inicializado.

- **successCallback** (function, opcional): Callback de éxito que recibe un boolean
- **errorCallback** (function, opcional): Callback de error

### `setScreenName(screenName, successCallback, errorCallback)`

Establece el nombre de la pantalla para rastreo de analytics.

- **screenName** (string): Nombre de la pantalla
- **successCallback** (function, opcional): Callback de éxito
- **errorCallback** (function, opcional): Callback de error

### `hasPermission(successCallback, errorCallback)`

Verifica si la aplicación tiene permisos para recopilar datos de analytics.

- **successCallback** (function, opcional): Callback de éxito que recibe un boolean
- **errorCallback** (function, opcional): Callback de error

## iOS Privacy Manifest

**Firebase incluye automáticamente el Privacy Manifest** a partir de la versión 10.22.0+:

- ✅ **Incluido automáticamente** en Firebase Analytics 10.26.0
- ✅ **Cumple con requisitos de Apple** para App Store (febrero 2025)
- ✅ **No requiere configuración manual** - Firebase lo maneja internamente
- ✅ **Compatible con iOS 17+** y App Store Connect

**Nota importante**: No es necesario crear manualmente el archivo `PrivacyInfo.xcprivacy`. Firebase SDK se encarga automáticamente de incluir el Privacy Manifest requerido por Apple.

## Versiones de Firebase

- **Firebase Analytics**: 10.26.0 (iOS) / 21.5.0 (Android)
- **Firebase Core**: 10.26.0 (iOS) / 21.1.1 (Android)
- **Google Services Plugin**: 4.4.0 (Android)

## Estructura del proyecto

```
cordova-plugin-firebase-analytics/
├── plugin.xml
├── package.json
├── README.md
├── www/
│   └── firebase-analytics.js
├── hooks/
│   ├── android_after_plugin_install.js   # Configura Google Services y copia google-services.json
│   └── ios_after_plugin_install.js       # Copia GoogleService-Info.plist
└── src/
    ├── android/
    │   └── FirebaseAnalyticsPlugin.java
    └── ios/
        └── FirebaseAnalyticsPlugin.swift
```

## Troubleshooting

### Error: "Firebase is not configured"

- Asegúrate de que `google-services.json` (Android) y `GoogleService-Info.plist` (iOS) estén en la raíz del proyecto
- Reconstruye la plataforma después de agregar los archivos

### Error: "Plugin not found"

- Verifica que el plugin esté instalado correctamente
- Ejecuta `cordova plugin list` para confirmar la instalación

### iOS Build Errors

- Asegúrate de usar Xcode 14+ para compilación
- Verifica que CocoaPods esté actualizado: `pod repo update`

## Contribuir

1. Fork el proyecto
2. Crea una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

## Licencia

Este proyecto está licenciado bajo la Licencia MIT - ver el archivo [LICENSE](LICENSE) para detalles.

## Soporte

Si encuentras algún problema o tienes preguntas, por favor abre un issue en GitHub.

## Repositorio

- **GitHub**: [https://github.com/kchomontiel/firebase-only-analytics-plugin](https://github.com/kchomontiel/firebase-only-analytics-plugin)
- **Rama**: `from0`

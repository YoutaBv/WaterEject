# Water Eject

Aplicación Flutter para Android que reproduce un tono de 165 Hz durante un
máximo de 30 segundos. El tono WAV se genera una sola vez en memoria y se repite
con `audioplayers`; el volumen inicial es moderado y puede ajustarse.

> El sonido no garantiza eliminar agua del interior del teléfono ni reparar
> daños. No uses la aplicación con auriculares ni mantengas el volumen al
> máximo. Si el dispositivo se mojó, sigue las recomendaciones de su fabricante.

## Requisitos para compilar en Windows

Instala Flutter SDK, Git for Windows, un JDK compatible y Android SDK Command-line
Tools; no hace falta Android Studio ni un emulador. Configura `C:\src\flutter\bin`
en `Path`, `ANDROID_HOME=C:\Android\Sdk` y las rutas de `platform-tools` y
`cmdline-tools\latest\bin` en `Path`.

Instala las herramientas Android y acepta sus licencias:

```powershell
sdkmanager --sdk_root=C:\Android\Sdk "platform-tools" "platforms;android-36" "build-tools;36.0.0"
sdkmanager --licenses
flutter doctor --android-licenses
flutter config --android-sdk C:\Android\Sdk
flutter doctor -v
```

La carpeta `android/` la genera el Flutter SDK. Para conservar intactos los
archivos de este proyecto, crea el scaffolding en una carpeta temporal y copia
solo su carpeta `android/`. Ejecuta desde esta carpeta:

```powershell
$scaffold = Join-Path $env:TEMP ("water-eject-" + [guid]::NewGuid().ToString("N"))
flutter create --platforms=android --project-name=water_eject --org=com.watereject $scaffold
Copy-Item (Join-Path $scaffold "android") ".\android" -Recurse
```

Después ejecuta:

```powershell
flutter pub get
flutter build apk --release
```

El APK se genera en
`build\app\outputs\flutter-apk\app-release.apk`. Con un teléfono conectado y la
depuración USB activada, puedes probarlo con `flutter devices` y `flutter install`.

## Crear el QR de descarga

Primero sube el APK a un alojamiento público, por ejemplo una publicación de
GitHub Releases, y copia la URL HTTPS directa del archivo. Después:

```powershell
python -m pip install -r requirements.txt
python tools\generar_qr.py --url "https://tu-dominio/app-release.apk"
```

El script crea `WaterEject_QR.png`. No se incluye un QR de ejemplo: el QR real
solo puede generarse cuando exista una URL pública del APK.

## Publicar código y APK con GitHub y Vercel

El repositorio incluye `public\index.html` para la página de descarga,
`public\app-release.apk` para el APK y `vercel.json` con la carpeta de salida
estática. Crea un repositorio público en GitHub, sube este proyecto y, en Vercel,
importa ese repositorio. Usa la carpeta `public` como directorio de salida y
despliega. La página incluirá el botón para descargar el APK.

Cuando Vercel proporcione la URL pública final, genera el QR apuntando
directamente al APK, sustituyendo `https://TU-PROYECTO.vercel.app` por esa URL:

```powershell
python tools\generar_qr.py --url "https://TU-PROYECTO.vercel.app/app-release.apk" --output "public\WaterEject_QR.png"
```

Para publicar una versión nueva, reemplaza `public\app-release.apk`, actualiza
el QR con la URL estable de Vercel y sube los cambios a GitHub.

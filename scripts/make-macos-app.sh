#!/bin/bash
# Ensambla un Tarot.app de macOS a partir del ejecutable que produce SwiftPM.
#
# El producto .executable de SwiftPM es un binario suelto: no tiene bundle, ni
# Info.plist, ni icono, asi que al abrirlo desde Xcode (DerivedData) o a mano
# macOS no puede mostrar el icono ni crear un tile normal en el Dock. Este
# script arma el .app que si lo hace, reutilizando el Info.plist y el icono
# que ya viven en el repositorio.
#
# Uso:
#   scripts/make-macos-app.sh                     # -> .build/Tarot.app
#   scripts/make-macos-app.sh --install           # ademas lo copia a ~/Applications
#   scripts/make-macos-app.sh --arch arm64        # si construiste para arm64
#
# Requisitos: haber compilado antes con `swift build`.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TRIPLE="$(uname -m)-apple-macosx"
ARCH="$(uname -m)"
INSTALL=0
for arg in "$@"; do
  case "$arg" in
    --install) INSTALL=1 ;;
    --arch) echo "usa --arch=<triple>" >&2 ;;
    --arch=*) ARCH="${arg#--arch=}" ;;
  esac
done
BUILD_DIR="$ROOT/.build/${ARCH}-apple-macosx/debug"
BINARIO="$BUILD_DIR/TarotApp"
APP="$ROOT/.build/Tarot.app"
ICONO="$ROOT/TarotApp/TarotMac.icns"
PLIST_FUENTE="$ROOT/TarotApp/Info-macOS.plist"  # el plist real del target macOS
BUNDLE_ID="com.nicole.tarot.mac"  # el mismo identificador que el target TarotMac de Xcode

[ -x "$BINARIO" ] || { echo "Falta el ejecutable $BINARIO. Ejecuta antes: swift build" >&2; exit 1; }
[ -f "$ICONO" ] || { echo "Falta el icono $ICONO" >&2; exit 1; }
[ -f "$PLIST_FUENTE" ] || { echo "Falta $PLIST_FUENTE" >&2; exit 1; }

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BINARIO" "$APP/Contents/MacOS/TarotApp"
# OJO: el accesor de recursos que genera SwiftPM busca el bundle en la RAIZ del
# .app (Bundle.main.bundleURL + nombre), no en Contents/Resources/ si no en
# segundo lugar en la ruta de compilacion. Copiarlo solo a Resources hacia que
# la app arrancase por el camino de reserva del directorio de compilacion y se
# cayera en cuanto ese directorio desaparecia.
for b in "$BUILD_DIR"/TarotApp_*.bundle; do
  if [ -e "$b" ]; then
    nombre="$(basename "$b")"
    cp -R "$b" "$APP/"
    ln -sfn "../../$nombre" "$APP/Contents/Resources/$nombre"
  fi
done
cp "$ICONO" "$APP/Contents/Resources/TarotMac.icns"

# El Info.plist del bundle se deriva del del repositorio (la fuente de verdad de
# la app) cambiando solo lo que en macOS es distinto del iOS.
python3 - "$PLIST_FUENTE" "$APP/Contents/Info.plist" "$BUNDLE_ID" <<'PY'
import io, plistlib, sys
origen, destino, bundle_id = sys.argv[1], sys.argv[2], sys.argv[3]
with io.open(origen, 'rb') as f:
    d = plistlib.load(f)
d.update({
    'CFBundleExecutable': 'TarotApp',
    'CFBundleIdentifier': bundle_id,
    'CFBundleName': 'Tarot',
    'CFBundleDisplayName': 'Tarot',
    'CFBundleIconFile': 'TarotMac',
    'CFBundlePackageType': 'APPL',
    'LSMinimumSystemVersion': '13.0',
    'NSPrincipalClass': 'NSApplication',
    'NSHighResolutionCapable': True,
})
d.pop('CFBundleSupportedPlatforms', None)
with io.open(destino, 'wb') as f:
    plistlib.dump(d, f)
PY

# El bundle de recursos vive en la raiz del .app porque asi lo busca el accesor de SwiftPM,
# y por eso macOS no deja sellar el bundle entero (solo admite Contents/). Se firma el
# ejecutable, que es lo que importa para uso local; para un .app sellado de verdad esta el
# target TarotMac del proyecto de Xcode.
codesign --force --deep --sign - "$APP" >/dev/null 2>&1 \
  || codesign --force --sign - "$APP/Contents/MacOS/TarotApp" >/dev/null 2>&1 \
  || echo "aviso: no se pudo firmar el ejecutable (el .app sigue siendo usable en local)" >&2

# Refrescar el registro de LaunchServices para que Finder/Dock vean el icono.
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$APP" 2>/dev/null || true

echo "Listo: $APP"
echo "  icono: $(/usr/libexec/PlistBuddy -c 'Print :CFBundleIconFile' "$APP/Contents/Info.plist" 2>/dev/null).icns"
if [ "$INSTALL" = "1" ]; then
  mkdir -p "$HOME/Applications"
  rm -rf "$HOME/Applications/Tarot.app"
  cp -R "$APP" "$HOME/Applications/Tarot.app"
  /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$HOME/Applications/Tarot.app" 2>/dev/null || true
  echo "Instalado en: $HOME/Applications/Tarot.app"
fi

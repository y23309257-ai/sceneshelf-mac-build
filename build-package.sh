#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
kit_root="$PWD"
trap 'printf "\n실패했습니다. 위 오류를 복사해 전달해 주세요.\n"; if [[ "${CI:-}" != "true" ]]; then read -r -p "Enter를 누르면 닫힙니다. " _; fi' ERR
if [[ "$(uname -s)" != "Darwin" ]]; then echo '이 빌드 도구는 Mac에서 실행하세요.'; exit 1; fi
case "$(uname -m)" in arm64) target_arch=arm64;; x86_64) target_arch=x64;; *) echo '지원하지 않는 Mac입니다.'; exit 1;; esac
for tool in /usr/bin/osacompile /usr/bin/pkgbuild /usr/bin/plutil /usr/libexec/PlistBuddy; do
  [[ -x "$tool" ]] || { echo "필요한 Mac 도구가 없습니다: $tool"; exit 1; }
done
stage="$(mktemp -d "$kit_root/build-${target_arch}.XXXXXX")"
app="$stage/SceneShelf.app"
runtime="$app/Contents/Resources/runtime"
/usr/bin/osacompile -o "$app" "$kit_root/MacLauncher.applescript"
mkdir -p "$runtime"
/usr/bin/ditto "$kit_root/payload/common" "$runtime"
/usr/bin/ditto "$kit_root/payload/$target_arch" "$runtime"
plist="$app/Contents/Info.plist"
for assignment in 'CFBundleIdentifier ai.sceneshelf.desktop' 'CFBundleShortVersionString 0.3.2'; do
  key="${assignment%% *}"; value="${assignment#* }"
  /usr/libexec/PlistBuddy -c "Set :$key $value" "$plist" 2>/dev/null || /usr/libexec/PlistBuddy -c "Add :$key string $value" "$plist"
done
/usr/libexec/PlistBuddy -c 'Add :CFBundleURLTypes array' "$plist"
/usr/libexec/PlistBuddy -c 'Add :CFBundleURLTypes:0 dict' "$plist"
/usr/libexec/PlistBuddy -c 'Add :CFBundleURLTypes:0:CFBundleURLName string ai.sceneshelf.connect' "$plist"
/usr/libexec/PlistBuddy -c 'Add :CFBundleURLTypes:0:CFBundleURLSchemes array' "$plist"
/usr/libexec/PlistBuddy -c 'Add :CFBundleURLTypes:0:CFBundleURLSchemes:0 string sceneshelf' "$plist"
/usr/bin/plutil -lint "$plist"
package="$stage/SceneShelf-Mac-$target_arch.pkg"
payload="$stage/payload"
components="$stage/components.plist"
mkdir -p "$payload"
/usr/bin/ditto "$app" "$payload/SceneShelf.app"
/usr/bin/pkgbuild --analyze --root "$payload" "$components"
# Always install into Applications, even if another copy is indexed on this Mac.
/usr/libexec/PlistBuddy -c 'Set :0:BundleIsRelocatable false' "$components"
/usr/bin/pkgbuild --root "$payload" --component-plist "$components" --identifier ai.sceneshelf.desktop --version 0.3.2 --install-location /Applications "$package"
/usr/sbin/pkgutil --check-signature "$package" || true
/usr/bin/shasum -a 256 "$package" > "$package.sha256"
printf '\n완료: %s\n.pkg와 .sha256 파일을 제작자에게 전달하세요.\n' "$package"
printf '이 파일은 서명·공증 전 테스트용 설치 파일입니다. 설치 전 Node.js 22.16 이상이 필요합니다.\n'
if [[ "${CI:-}" != "true" ]]; then
  /usr/bin/open -R "$package"
  read -r -p 'Enter를 누르면 닫힙니다. ' _
fi

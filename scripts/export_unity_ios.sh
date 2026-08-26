#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
unity_editor="${UNITY_EDITOR:-/Applications/Unity/Hub/Editor/6000.3.22f1/Unity.app/Contents/MacOS/Unity}"
editor_root="$(cd "$(dirname "$unity_editor")/../../.." && pwd)"
ios_support="$editor_root/PlaybackEngines/iOSSupport"
export_path="$repo_root/ios/unityLibrary"

if [[ ! -x "$unity_editor" ]]; then
  echo "Unity Editor was not found: $unity_editor" >&2
  echo "Set UNITY_EDITOR to the Unity executable path and run again." >&2
  exit 1
fi

if [[ ! -d "$ios_support" ]]; then
  echo "Unity iOS Build Support is missing for this Editor." >&2
  echo "Open Unity Hub > Installs > Unity 6.3.22f1 > Add modules, then install iOS Build Support." >&2
  exit 1
fi

"$unity_editor" \
  -batchmode \
  -nographics \
  -accept-apiupdate \
  -quit \
  -projectPath "$repo_root/MonsterPlanet3D" \
  -buildTarget iOS \
  -executeMethod MonsterPlanet3D.EditorTools.PrototypeSceneBuilder.ExportFlutterIosLibrary \
  -exportPath "$export_path"

ruby "$repo_root/scripts/link_unity_ios.rb"
echo "Unity iOS library exported and linked."

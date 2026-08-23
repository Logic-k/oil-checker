#!/bin/sh
# Vercel 빌드 환경에 Flutter SDK 설치 (빌드 캐시에 보관되어 재사용됨)
# repo 루트가 아닌 $HOME에 설치해 프로젝트 오염과 배포 크기 증가를 방지한다.
set -e

if [ ! -d "$HOME/flutter" ]; then
  echo "[install_flutter] cloning Flutter SDK to $HOME/flutter"
  git clone --depth 1 -b stable https://github.com/flutter/flutter.git "$HOME/flutter"
else
  echo "[install_flutter] Flutter SDK already present at $HOME/flutter"
fi

export PATH="$HOME/flutter/bin:$PATH"
flutter config --no-analytics
flutter --version

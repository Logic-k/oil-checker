#!/bin/sh
# Flutter web 릴리스 빌드 (Vercel Build Command에서 호출)
# 산출물은 build/web — vercel.json의 outputDirectory로 지정되어 있다.
set -e

export PATH="$HOME/flutter/bin:$PATH"
flutter pub get
flutter build web --release

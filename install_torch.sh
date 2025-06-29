#!/bin/bash
set -e

echo "🔥 PyTorch 2.8 (cu128 nightly) 설치 중..."

pip install --pre torch==2.8.0 torchvision==0.17.0 \
  --extra-index-url https://download.pytorch.org/whl/nightly/cu128

echo "✅ PyTorch 설치 완료"

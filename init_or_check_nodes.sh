#!/bin/bash
set -e

echo "🌀 RunPod 재시작 또는 완전 종료 후 복구 절차 시작"

# 기본 경로 설정
CUSTOM_NODE_DIR="/workspace/ComfyUI/custom_nodes"
BACKUP_DIR="/opt/backup_nodes"
MARKER_DIR="/opt/comfy_node_markers"

# 디렉토리 생성
mkdir -p "$CUSTOM_NODE_DIR"
mkdir -p "$MARKER_DIR"

# 1️⃣ custom_nodes 폴더가 비었을 경우 백업에서 복사
if [ -z "$(ls -A "$CUSTOM_NODE_DIR")" ]; then
  echo "📁 custom_nodes 비어 있음 → 백업에서 복구 시작"
  cp -r "$BACKUP_DIR"/* "$CUSTOM_NODE_DIR"/
else
  echo "📂 custom_nodes 이미 존재 → 복구 생략"
fi

# 2️⃣ 각 노드별 의존성 설치 확인 및 복구
cd "$CUSTOM_NODE_DIR"

for d in */; do
  req_file="${d}requirements.txt"
  marker_file="$MARKER_DIR/${d%/}.installed"

  if [ -f "$req_file" ]; then
    if [ -f "$marker_file" ]; then
      echo "⏩ $d 이미 설치됨, 건너뜀"
      continue
    fi

    echo "📦 $d 의존성 설치 중..."
    if pip install -r "$req_file"; then
      touch "$marker_file"
      echo "✅ $d 의존성 설치 완료"
    else
      echo "⚠️ $d 의존성 설치 실패 (무시하고 계속 진행)"
    fi
  else
    echo "ℹ️ $d 에 requirements.txt 없음, 건너뜀"
  fi
done

echo "🎉 모든 커스텀 노드 복구 및 의존성 설치 완료"

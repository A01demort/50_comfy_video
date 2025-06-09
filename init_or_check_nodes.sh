#!/bin/bash
set -e

echo "🌀 완전 휘발방지형 커스텀 노드 & pip 복구 시작"

CUSTOM_NODE_DIR="/workspace/ComfyUI/custom_nodes"
BACKUP_DIR="/opt/backup_nodes"
MARKER_DIR="/workspace/.pip_markers"
PIP_TARGET_DIR="/workspace/.pip_installs"

mkdir -p "$CUSTOM_NODE_DIR" "$MARKER_DIR" "$PIP_TARGET_DIR"

# PYTHONPATH에 pip 설치 경로 추가
export PYTHONPATH="$PIP_TARGET_DIR:$PYTHONPATH"

# 1️⃣ custom_nodes 복구
if [ -z "$(ls -A "$CUSTOM_NODE_DIR")" ]; then
  echo "📁 custom_nodes 비어 있음 → 백업에서 복구"
  cp -r "$BACKUP_DIR"/* "$CUSTOM_NODE_DIR"/
else
  echo "📂 custom_nodes 존재 → 복구 생략"
fi

cd "$CUSTOM_NODE_DIR"

# 2️⃣ 노드별 의존성 설치
for d in */; do
  req_file="${d}requirements.txt"
  marker_file="$MARKER_DIR/${d%/}.installed"

  if [ -f "$req_file" ]; then
    reinstall_needed=false

    if [ ! -f "$marker_file" ]; then
      echo "📌 $d → 설치 마커 없음 → 설치 필요"
      reinstall_needed=true
    else
      echo "🧪 pip check로 의존성 상태 확인..."
      if ! PYTHONPATH="$PIP_TARGET_DIR" pip check > /dev/null 2>&1; then
        echo "⚠️ $d → 의존성 깨짐 → 재설치 필요"
        reinstall_needed=true
      fi
    fi

    if [ "$reinstall_needed" = true ]; then
      echo "📦 $d 의존성 설치 중... → $PIP_TARGET_DIR"
      if pip install --target="$PIP_TARGET_DIR" -r "$req_file"; then
        touch "$marker_file"
        echo "✅ $d 설치 완료"
      else
        echo "❌ $d 설치 실패 (무시하고 진행)"
      fi
    else
      echo "⏩ $d 이미 설치됨 → 건너뜀"
    fi
  else
    echo "ℹ️ $d 에 requirements.txt 없음 → 건너뜀"
  fi
done

# 3️⃣ 전체 pip 상태 점검
echo "🔍 전체 pip 상태 점검 중..."
if ! PYTHONPATH="$PIP_TARGET_DIR" pip check; then
  echo "❗ 전체 pip 환경 이상 있음. 필요한 경우 수동 확인 필요"
else
  echo "✅ 전체 pip 상태 양호"
fi

echo "🎉 커스텀 노드 & pip 설치 복구 완료"

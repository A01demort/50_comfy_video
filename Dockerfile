FROM nvidia/cuda:12.1.1-cudnn8-runtime-ubuntu20.04

ENV DEBIAN_FRONTEND=noninteractive
ENV PIP_CACHE_DIR=/workspace/.cache/pip

# 시스템 및 JupyterLab 관련 패키지 설치
RUN apt-get update && apt-get install -y \
    git wget curl ffmpeg libgl1 \
    build-essential libssl-dev zlib1g-dev libbz2-dev \
    libreadline-dev libsqlite3-dev libncurses5-dev \
    libncursesw5-dev xz-utils tk-dev libffi-dev \
    liblzma-dev software-properties-common \
    locales sudo tzdata xterm nano \
    nodejs npm dos2unix netcat && \
    apt-get clean

# 정확한 Python 3.10.6 설치
WORKDIR /tmp
RUN wget https://www.python.org/ftp/python/3.10.6/Python-3.10.6.tgz && \
    tar xzf Python-3.10.6.tgz && cd Python-3.10.6 && \
    ./configure --enable-optimizations && \
    make -j$(nproc) && make altinstall && \
    ln -sf /usr/local/bin/python3.10 /usr/bin/python && \
    ln -sf /usr/local/bin/python3.10 /usr/bin/python3 && \
    ln -sf /usr/local/bin/pip3.10 /usr/bin/pip && \
    ln -sf /usr/local/bin/pip3.10 /usr/local/bin/pip && \
    cd / && rm -rf /tmp/*

# ComfyUI 설치
WORKDIR /workspace
RUN git clone https://github.com/comfyanonymous/ComfyUI.git /workspace/ComfyUI
WORKDIR /workspace/ComfyUI

# Python 의존성 설치
RUN pip install -r requirements.txt && \
    pip install torch==2.7.1 torchvision==0.22.1+cu126 torchaudio==2.7.1+cu126 --extra-index-url https://download.pytorch.org/whl/cu126

# Node.js 18 재설치
RUN apt-get remove -y nodejs npm && \
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y nodejs && \
    node -v && npm -v

# Jupyter 설치
RUN pip install --force-reinstall jupyterlab==3.6.6 jupyter-server==1.23.6

# Jupyter 설정
RUN mkdir -p /root/.jupyter && \
    echo "c.NotebookApp.allow_origin = '*'\n\
c.NotebookApp.ip = '0.0.0.0'\n\
c.NotebookApp.open_browser = False\n\
c.NotebookApp.token = ''\n\
c.NotebookApp.password = ''\n\
c.NotebookApp.terminado_settings = {'shell_command': ['/bin/bash']}\n\
c.ServerApp.serve_extensions = True" > /root/.jupyter/jupyter_notebook_config.py

# 커스텀 노드 git clone (20개 넘게)
RUN mkdir -p /workspace/ComfyUI/custom_nodes && cd /workspace/ComfyUI/custom_nodes && \
    git clone https://github.com/ltdrdata/ComfyUI-Manager.git || echo '⚠️ Manager 실패' && \
    git clone https://github.com/pythongosssss/ComfyUI-Custom-Scripts.git || echo '⚠️ Scripts 실패' && \
    git clone https://github.com/rgthree/rgthree-comfy.git || echo '⚠️ rgthree 실패' && \
    git clone https://github.com/WASasquatch/was-node-suite-comfyui.git || echo '⚠️ WAS 실패' && \
    git clone https://github.com/kijai/ComfyUI-KJNodes.git || echo '⚠️ KJNodes 실패' && \
    git clone https://github.com/cubiq/ComfyUI_essentials.git || echo '⚠️ Essentials 실패' && \
    git clone https://github.com/city96/ComfyUI-GGUF.git || echo '⚠️ GGUF 실패' && \
    git clone https://github.com/welltop-cn/ComfyUI-TeaCache.git || echo '⚠️ TeaCache 실패' && \
    git clone https://github.com/kaibioinfo/ComfyUI_AdvancedRefluxControl.git || echo '⚠️ ARC 실패' && \
    git clone https://github.com/Suzie1/ComfyUI_Comfyroll_CustomNodes.git || echo '⚠️ Comfyroll 실패' && \
    git clone https://github.com/cubiq/PuLID_ComfyUI.git || echo '⚠️ PuLID 실패' && \
    git clone https://github.com/sipie800/ComfyUI-PuLID-Flux-Enhanced.git || echo '⚠️ Flux 실패' && \
    git clone https://github.com/Gourieff/ComfyUI-ReActor.git || echo '⚠️ ReActor 실패' && \
    git clone https://github.com/yolain/ComfyUI-Easy-Use.git || echo '⚠️ EasyUse 실패' && \
    git clone https://github.com/PowerHouseMan/ComfyUI-AdvancedLivePortrait.git || echo '⚠️ LivePortrait 실패' && \
    git clone https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git || echo '⚠️ VideoHelper 실패' && \
    git clone https://github.com/Jonseed/ComfyUI-Detail-Daemon.git || echo '⚠️ Daemon 실패' && \
    git clone https://github.com/ssitu/ComfyUI_UltimateSDUpscale.git || echo '⚠️ Upscale 실패' && \
    git clone https://github.com/risunobushi/comfyUI_FrequencySeparation_RGB-HSV.git || echo '⚠️ Frequency 실패' && \
    git clone https://github.com/silveroxides/ComfyUI_bnb_nf4_fp4_Loaders.git || echo '⚠️ NF4 실패' && \
    git clone https://github.com/kijai/ComfyUI-FramePackWrapper.git || echo '⚠️ FramePackWrapper 실패'

# segment-anything + ONNX 모델 설치
RUN git clone https://github.com/facebookresearch/segment-anything.git /workspace/segment-anything && \
    pip install -e /workspace/segment-anything && \
    mkdir -p /workspace/ComfyUI/models/insightface && \
    wget -O /workspace/ComfyUI/models/insightface/inswapper_128.onnx https://huggingface.co/datasets/Gourieff/ReActor/resolve/main/models/inswapper_128.onnx

# Python 패키지 추가 설치 (호환 버전 지정 + facelib 깃허브)
RUN pip install --no-cache-dir \
    GitPython onnx onnxruntime opencv-python-headless tqdm requests \
    scikit-image piexif packaging protobuf scipy einops pandas matplotlib imageio[ffmpeg] pyzbar pillow numba \
    gguf dill insightface ftfy ultralytics timm==0.9.2 \
    mtcnn==0.1.1 facexlib basicsr gfpgan realesrgan \
    diffusers==0.24.0 transformers==4.39.3 huggingface_hub==0.20.3 peft==0.7.1 \
    bitsandbytes==0.42.0.post2 xformers sageattention

# facelib 깃허브에서 직접 설치
RUN git clone https://github.com/serengil/facelib.git /tmp/facelib && \
    pip install /tmp/facelib && rm -rf /tmp/facelib


# bitsandbytes CUDA 링크 수동 연결
RUN ln -s /usr/local/lib/python3.10/site-packages/bitsandbytes/libbitsandbytes_cuda12x/libbitsandbytes_cuda121.so \
           /usr/local/lib/python3.10/site-packages/bitsandbytes/libbitsandbytes_cuda12x/libbitsandbytes_cuda126.so || true

# 커스텀 설정 추가
RUN echo '{ "ffmpeg_bin_path": "/usr/bin/ffmpeg" }' > /workspace/ComfyUI/custom_nodes/was-node-suite-comfyui/was_suite_config.json || true

# 스크립트 복사 및 권한
RUN mkdir -p /workspace/A1
COPY init_or_check_nodes.sh /workspace/A1/init_or_check_nodes.sh
COPY Hugging_down_a1.sh /workspace/A1/Hugging_down_a1.sh
COPY Framepack_down.sh /workspace/A1/Framepack_down.sh
RUN chmod +x /workspace/A1/*.sh && dos2unix /workspace/A1/*.sh

# 포트 및 볼륨 설정
VOLUME ["/workspace"]
EXPOSE 8188
EXPOSE 8888

# CMD: Jupyter 완전히 뜬 뒤 스크립트 실행 → ComfyUI 실행
CMD bash -c '\
echo "🌀 A1(AI는 에이원) 컨테이너 시작" && \
rm -rf /root/.local/share/jupyter/lab /root/.local/share/jupyter/runtime && \
jupyter lab --ip=0.0.0.0 --port=8888 --allow-root \
--ServerApp.root_dir=/workspace \
--ServerApp.token="" --ServerApp.password="" & \
echo "⏳ JupyterLab 기동 대기 중..." && \
while ! nc -z localhost 8888; do sleep 1; done && \
echo "✅ JupyterLab 포트 열림 확인" && \
sleep 2 && \
bash /workspace/A1/init_or_check_nodes.sh && \
echo "🚀 커스텀 노드 복구 완료" && \
python -u /workspace/ComfyUI/main.py --listen 0.0.0.0 --port=8188 \
--front-end-version Comfy-Org/ComfyUI_frontend@latest'

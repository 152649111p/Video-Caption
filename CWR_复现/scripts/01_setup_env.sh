#!/bin/bash
set -e
ROOT="/root/autodl-tmp/CLIP_prefix_caption/Detic/1-1代码路径/大论文-视频字幕生成专项_BLIP-2_for_Video"
CODE="$ROOT/mllm-video-captioner"

echo "[1/6] (可选) 装 ffmpeg 命令行 — 仅用于 decord 容错与日常排查"
if command -v apt-get >/dev/null 2>&1; then
    apt-get update -y >/dev/null 2>&1 || true
    apt-get install -y ffmpeg pkg-config >/dev/null 2>&1 || \
      echo "  ⚠️ 系统 ffmpeg 未装上，无影响（PyAV 走 wheel 不用系统库）"
fi

echo "[2/6] 替换 opencv 为 headless 版（无显示服务器友好）..."
pip uninstall -y opencv-python opencv-python-headless || true
pip install opencv-python-headless==4.5.5.64

echo "[3/6] 安装关键依赖（PyAV 改用 12.3.0 → 走 manylinux wheel，不再源码编译）..."
pip install \
    "av==12.3.0" \
    fairscale==0.4.4 \
    webdataset==0.2.86 \
    iopath==0.1.10 \
    omegaconf==2.3.0 \
    yacs==0.1.8 \
    timm==0.6.13 \
    scipy==1.10.1 \
    scikit-image==0.21.0 \
    matplotlib==3.7.5 \
    contexttimer==0.3.3 \
    wandb

echo "[4/6] 安装 pytorchvideo（--no-deps 避免拉旧 torch 覆盖你的 2.1.2）..."
pip install pytorchvideo==0.1.5 --no-deps
pip install fvcore==0.1.5.post20221221 --no-deps
pip install parameterized --no-deps || true

echo "[5/6] 安装 LAVIS 为可编辑包（--no-deps 避免被 requirements.txt 把 torch 降到 1.13）..."
cd "$CODE"
pip install -e . --no-deps

echo "[6/6] 关键依赖自检..."
python - <<'PY'
import importlib, torch
mods = ["torch","torchvision","transformers","accelerate","peft",
        "decord","av","pytorchvideo","fairscale","webdataset",
        "iopath","omegaconf","yacs","timm","contexttimer",
        "pycocoevalcap","numpy","PIL","cv2","scipy","skimage",
        "fvcore","lavis"]
ok, bad = [], []
for m in mods:
    try:
        x = importlib.import_module(m)
        ver = getattr(x, "__version__", "ok")
        ok.append(f"  {m:<14} {ver}")
    except Exception as e:
        bad.append(f"  {m:<14} ❌ {e}")
print("\n".join(ok))
if bad:
    print("\n❌ 失败:")
    print("\n".join(bad))
print()
print("CUDA available :", torch.cuda.is_available())
print("Device         :", torch.cuda.get_device_name(0) if torch.cuda.is_available() else "CPU only")
PY

echo ""
echo "✅ 环境补全完成"

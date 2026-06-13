#!/bin/bash
set -e
ROOT="/root/autodl-tmp/CLIP_prefix_caption/Detic/1-1代码路径/大论文-视频字幕生成专项_BLIP-2_for_Video"
PRETRAINED="$ROOT/01.模型预训练权重模型"
mkdir -p "$PRETRAINED"

echo "================================================================"
echo ">>> [1/2] 下载 BLIP-2 FlanT5-XL 主权重 (~16 GB)"
echo "================================================================"
wget -c \
  "https://storage.googleapis.com/sfr-vision-language-research/LAVIS/models/BLIP2/blip2_pretrained_flant5xl.pth" \
  -O "$PRETRAINED/blip2_pretrained_flant5xl.pth"

echo ""
echo "================================================================"
echo ">>> [2/2] 下载 google/flan-t5-xl 到本地 HF 缓存 (~11 GB)"
echo "================================================================"
export HF_HOME="$PRETRAINED/hf_cache"
mkdir -p "$HF_HOME"

# 如果默认源慢，取消下面这行注释走 hf-mirror
# export HF_ENDPOINT="https://hf-mirror.com"

python - <<'PY'
import os, time
from transformers import T5TokenizerFast, T5ForConditionalGeneration
cache = os.environ["HF_HOME"]

t0 = time.time()
print(">>> Downloading tokenizer ...")
T5TokenizerFast.from_pretrained("google/flan-t5-xl", cache_dir=cache)
print(f"    tokenizer done ({time.time()-t0:.1f}s)")

t0 = time.time()
print(">>> Downloading model (10-30 min depending on bandwidth) ...")
T5ForConditionalGeneration.from_pretrained("google/flan-t5-xl", cache_dir=cache)
print(f"    model done ({time.time()-t0:.1f}s)")

print()
print("✅ flan-t5-xl 已就绪 ->", cache)
PY

echo ""
echo "================================================================"
echo "✅ 全部预训练权重下载完成"
echo "================================================================"
echo ""
echo "实际占用:"
du -sh "$PRETRAINED"/* 2>/dev/null

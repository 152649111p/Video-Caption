#!/bin/bash
set -e
ROOT="/root/autodl-tmp/CLIP_prefix_caption/Detic/1-1代码路径/大论文-视频字幕生成专项_BLIP-2_for_Video"
CODE="$ROOT/mllm-video-captioner"
CWR="$CODE/CWR_复现"
PRETRAINED="$ROOT/01.模型预训练权重模型"

CKPT="$1"
if [ -z "$CKPT" ] || [ ! -f "$CKPT" ]; then
    echo "❌ 用法: bash 05_evaluate_small.sh <checkpoint绝对路径>"
    exit 1
fi

# 重建软链接
mkdir -p /root/.cache/torch/hub/checkpoints/
ln -sf "$PRETRAINED/eva/eva_vit_g.pth" /root/.cache/torch/hub/checkpoints/eva_vit_g.pth
mkdir -p /home/anonymous/new_ssd/lavis_datasets/msrvtt/
ln -sf "$ROOT/00.数据集/msrvtt/videos" /home/anonymous/new_ssd/lavis_datasets/msrvtt/videos
mkdir -p /home/anonymous/new_ssd/lavis_datasets/msrvtt_gt/
ln -sf "$ROOT/00.数据集/msrvtt_gt/msrvtt_test_gt.json" \
       /home/anonymous/new_ssd/lavis_datasets/msrvtt_gt/msrvtt_test_gt.json
# 截断GT软链接
ln -sf /home/anonymous/new_ssd/lavis_datasets/msrvtt_gt/msrvtt_test_small_gt.json \
       /home/anonymous/new_ssd/lavis_datasets/msrvtt_gt/msrvtt_test_small_gt.json 2>/dev/null || true

TMP="$CWR/configs/_eval_small_tmp_$(date +%s).yaml"
sed "s#REPLACE_BY_05_SCRIPT#$CKPT#g" "$CWR/configs/_eval_small.yaml" > "$TMP"

LOG="$CWR/logs/eval_small_$(date +%Y%m%d_%H%M%S).log"

export PYTHONPATH="$CWR:$CODE:${PYTHONPATH:-}"
export HF_HOME="$PRETRAINED/hf_cache"
export TRANSFORMERS_OFFLINE=1
export HF_HUB_OFFLINE=1
export TOKENIZERS_PARALLELISM=false

cd "$CODE"
python -m torch.distributed.run \
    --nproc_per_node=1 \
    --master_port=29502 \
    evaluate.py \
    --cfg-path "$TMP" \
    2>&1 | tee "$LOG"

rm -f "$TMP"
echo ""
echo "✅ 快速评估完成，日志: $LOG"

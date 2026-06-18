#!/bin/bash
set -e
ROOT="/root/autodl-tmp/CLIP_prefix_caption/Detic/1-1代码路径/大论文-视频字幕生成专项_BLIP-2_for_Video"
CODE="$ROOT/mllm-video-captioner"
CWR="$CODE/CWR_复现"
PRETRAINED="$ROOT/01.模型预训练权重模型"

CKPT="$1"
if [ -z "$CKPT" ] || [ ! -f "$CKPT" ]; then
    echo "❌ 用法: bash 06_evaluate_scst.sh <checkpoint绝对路径>"
    exit 1
fi

TMP="$CWR/configs/_eval_scst_tmp_$(date +%s).yaml"
sed "s#REPLACE_BY_05_SCRIPT#$CKPT#g" \
    "$CWR/configs/caption_msrvtt_flant5xl_eval_scst.yaml" > "$TMP"

LOG="$CWR/logs/eval_scst_$(date +%Y%m%d_%H%M%S).log"
mkdir -p "$CWR/logs"

export PYTHONPATH="$CWR:$CODE:${PYTHONPATH:-}"
export HF_HOME="$PRETRAINED/hf_cache"
export TOKENIZERS_PARALLELISM=false
export TRANSFORMERS_OFFLINE=1
export HF_HUB_OFFLINE=1

cd "$CODE"
CUDA_VISIBLE_DEVICES=0 python -m torch.distributed.run \
    --nproc_per_node=1 \
    --master_port=29503 \
    evaluate.py \
    --cfg-path "$TMP" \
    2>&1 | tee "$LOG"

rm -f "$TMP"
echo ""
echo "✅ 评估完成"
echo "=== 最终指标 ==="
grep -E "CIDEr|Bleu|ROUGE|METEOR|agg_metrics" "$LOG" | tail -15

#!/bin/bash
set -e
ROOT="/root/autodl-tmp/CLIP_prefix_caption/Detic/1-1代码路径/大论文-视频字幕生成专项_BLIP-2_for_Video"
CODE="$ROOT/mllm-video-captioner"
CWR="$CODE/CWR_复现"
PRETRAINED="$ROOT/01.模型预训练权重模型"

CKPT="$1"
if [ -z "$CKPT" ] || [ ! -f "$CKPT" ]; then
    echo "❌ 用法: bash 05_evaluate_stage1.sh <checkpoint绝对路径>"
    exit 1
fi

TMP="$CWR/configs/_eval_tmp_$(date +%s).yaml"
sed "s#REPLACE_BY_05_SCRIPT#$CKPT#g" \
    "$CWR/configs/caption_msrvtt_flant5xl_eval.yaml" > "$TMP"

LOG="$CWR/logs/eval_$(date +%Y%m%d_%H%M%S).log"

export PYTHONPATH="$CWR:$CODE:${PYTHONPATH:-}"
export HF_HOME="$PRETRAINED/hf_cache"
export TOKENIZERS_PARALLELISM=false

cd "$CODE"
python -m torch.distributed.run \
    --nproc_per_node=1 \
    --master_port=29501 \
    evaluate.py \
    --cfg-path "$TMP" \
    2>&1 | tee "$LOG"

rm -f "$TMP"
echo ""
echo "✅ 评估完成, 指标日志: $LOG"

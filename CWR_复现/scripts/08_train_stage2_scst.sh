#!/bin/bash
set -e
ROOT="/root/autodl-tmp/CLIP_prefix_caption/Detic/1-1代码路径/大论文-视频字幕生成专项_BLIP-2_for_Video"
CODE="$ROOT/mllm-video-captioner"
CWR="$CODE/CWR_复现"
PRETRAINED="$ROOT/01.模型预训练权重模型"
LOG="$CWR/logs/stage2_scst_$(date +%Y%m%d_%H%M%S).log"

export PYTHONPATH="$CWR:$CODE:${PYTHONPATH:-}"
export HF_HOME="$PRETRAINED/hf_cache"
export TOKENIZERS_PARALLELISM=false
export NCCL_DEBUG=WARN
export TRANSFORMERS_OFFLINE=1
export HF_HUB_OFFLINE=1

cd "$CODE"
python -m torch.distributed.run \
    --nproc_per_node=3 \
    --master_port=29502 \
    train.py \
    --cfg-path "$CWR/configs/caption_msrvtt_flant5xl_ft_scst.yaml" \
    2>&1 | tee "$LOG"

echo ""
echo "✅ Stage 2 (SCST) 训练完成"
echo "   产物: $ROOT/02.模型训练存放（SCST）/Caption_msrvtt/"
echo "   日志: $LOG"

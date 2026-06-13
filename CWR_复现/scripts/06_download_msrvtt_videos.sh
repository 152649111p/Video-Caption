#!/bin/bash
set -e
ROOT="/root/autodl-tmp/CLIP_prefix_caption/Detic/1-1代码路径/大论文-视频字幕生成专项_BLIP-2_for_Video"
DATA="$ROOT/00.数据集"
VID_DIR="$DATA/msrvtt/videos"
TMP_DIR="$DATA/msrvtt_modelscope_tmp"
mkdir -p "$VID_DIR" "$TMP_DIR"

echo "[$(date '+%H:%M:%S')] ▶ Step1: ModelScope 下载 MSR-VTT..."

python3 - <<'PY'
import os, sys, glob, shutil

TMP_DIR = "/root/autodl-tmp/CLIP_prefix_caption/Detic/1-1代码路径/大论文-视频字幕生成专项_BLIP-2_for_Video/00.数据集/msrvtt_modelscope_tmp"
VID_DIR = "/root/autodl-tmp/CLIP_prefix_caption/Detic/1-1代码路径/大论文-视频字幕生成专项_BLIP-2_for_Video/00.数据集/msrvtt/videos"

# ── 下载 ──
from modelscope.hub.snapshot_download import snapshot_download
print(f"[下载] 开始，目标缓存: {TMP_DIR}")
print(f"[下载] 数据集约 6~7GB，预计 10~30 分钟，请耐心等待...")

local_dir = snapshot_download(
    model_id   = "AI-ModelScope/msr-vtt",
    cache_dir  = TMP_DIR,
)
print(f"[下载] 完成，本地路径: {local_dir}")

# ── 整理 mp4 → videos/ ──
print(f"\n[整理] 搜索 mp4 文件...")
mp4s = glob.glob(os.path.join(local_dir, "**", "*.mp4"), recursive=True)
print(f"[整理] 找到 {len(mp4s)} 个 mp4")

if len(mp4s) == 0:
    # 展示目录结构辅助排查
    print("[整理] ⚠️  未找到 mp4，打印目录结构：")
    for root, dirs, files in os.walk(local_dir):
        depth = root.replace(local_dir, "").count(os.sep)
        indent = "  " * depth
        print(f"{indent}{os.path.basename(root)}/")
        if depth >= 2:
            dirs.clear()
        for f in files[:5]:
            print(f"{indent}  {f}")
    sys.exit(1)

moved, skipped = 0, 0
for src in sorted(mp4s):
    fname = os.path.basename(src)
    dst   = os.path.join(VID_DIR, fname)
    if os.path.exists(dst):
        skipped += 1
        continue
    try:
        os.link(src, dst)       # 硬链接：零拷贝、不占额外空间
    except OSError:
        shutil.copy2(src, dst)  # 跨设备时回退到复制
    moved += 1
    if moved % 1000 == 0:
        print(f"[整理] 已处理 {moved} 个...")

total = len([f for f in os.listdir(VID_DIR) if f.endswith(".mp4")])
print(f"\n[整理] 完成：移动 {moved}，跳过(已有) {skipped}")
print(f"[统计] videos/ 当前: {total}/10000 个 mp4")

if total == 10000:
    print("[统计] 🎉 视频文件完全齐全，可以启动训练！")
elif total > 0:
    miss = sorted(
        [f"video{i}.mp4" for i in range(10000)
         if not os.path.exists(os.path.join(VID_DIR, f"video{i}.mp4"))]
    )[:20]
    print(f"[统计] ⚠️  还缺 {10000 - total} 个，前20个缺失: {miss}")
else:
    print("[统计] ❌ videos/ 仍为空，请检查下载源")
PY

echo ""
echo "[$(date '+%H:%M:%S')] ✅ 脚本执行完毕"
echo "  当前视频数: $(find "$VID_DIR" -name '*.mp4' | wc -l) / 10000"

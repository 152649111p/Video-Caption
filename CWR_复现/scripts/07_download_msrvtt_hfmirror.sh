#!/bin/bash
set -e

VID_DIR="/root/autodl-tmp/CLIP_prefix_caption/Detic/1-1代码路径/大论文-视频字幕生成专项_BLIP-2_for_Video/00.数据集/msrvtt/videos"
TMP_DIR="/root/autodl-tmp/CLIP_prefix_caption/Detic/1-1代码路径/大论文-视频字幕生成专项_BLIP-2_for_Video/00.数据集/msrvtt_hfmirror_tmp"
mkdir -p "$VID_DIR" "$TMP_DIR"

echo "[$(date '+%H:%M:%S')] ▶ hf-mirror 下载 friedrichor/MSR-VTT ..."

# 使用国内镜像加速
export HF_ENDPOINT="https://hf-mirror.com"
export HUGGINGFACE_HUB_VERBOSITY="info"

python3 - << 'PYEOF'
import os, sys, glob, shutil, zipfile

TMP_DIR = "/root/autodl-tmp/CLIP_prefix_caption/Detic/1-1代码路径/大论文-视频字幕生成专项_BLIP-2_for_Video/00.数据集/msrvtt_hfmirror_tmp"
VID_DIR = "/root/autodl-tmp/CLIP_prefix_caption/Detic/1-1代码路径/大论文-视频字幕生成专项_BLIP-2_for_Video/00.数据集/msrvtt/videos"

os.environ["HF_ENDPOINT"] = "https://hf-mirror.com"

from huggingface_hub import snapshot_download

print("[下载] 使用 hf-mirror 下载 friedrichor/MSR-VTT")
print("[下载] 只下载 MSRVTT_Videos.zip，跳过其他文件（约6~7GB）...")

local_dir = snapshot_download(
    repo_id="friedrichor/MSR-VTT",
    repo_type="dataset",
    local_dir=TMP_DIR,
    allow_patterns=["MSRVTT_Videos.zip"],   # 只下视频zip
    ignore_patterns=["*.json","*.csv","*.pkl","*.md","*.txt"],
    resume_download=True,
)
print(f"[下载] ✅ 完成，路径: {local_dir}")

# 找zip
zips = glob.glob(os.path.join(TMP_DIR, "**", "*.zip"), recursive=True)
print(f"\n[解压] 找到 {len(zips)} 个 zip")

if not zips:
    print("[解压] ❌ 未找到 zip，打印目录结构：")
    for r, d, files in os.walk(TMP_DIR):
        depth = r.replace(TMP_DIR, "").count(os.sep)
        if depth > 3:
            continue
        print("  " * depth + os.path.basename(r) + "/")
        for f in files[:5]:
            print("  " * (depth+1) + f)
    sys.exit(1)

for z in zips:
    size_gb = os.path.getsize(z) / 1024**3
    print(f"[解压] {os.path.basename(z)}  ({size_gb:.1f} GB) ...")
    with zipfile.ZipFile(z, 'r') as zf:
        names = zf.namelist()
        print(f"[解压] zip内文件数: {len(names)}，首个: {names[0] if names else '空'}")
        zf.extractall(TMP_DIR)
    print(f"[解压] ✅ 完成")

# 整理 mp4 → videos/
mp4s = glob.glob(os.path.join(TMP_DIR, "**", "*.mp4"), recursive=True)
print(f"\n[整理] 找到 {len(mp4s)} 个 mp4")

moved, skipped = 0, 0
for src in sorted(mp4s):
    fname = os.path.basename(src)
    dst   = os.path.join(VID_DIR, fname)
    if os.path.exists(dst):
        skipped += 1
        continue
    try:
        os.link(src, dst)
    except OSError:
        shutil.copy2(src, dst)
    moved += 1
    if moved % 1000 == 0:
        print(f"[整理] 已处理 {moved} 个...")

total = len([f for f in os.listdir(VID_DIR) if f.endswith(".mp4")])
print(f"\n[统计] 移动={moved}，跳过={skipped}，videos/共 {total}/10000 个")
if total == 10000:
    print("[统计] 🎉 视频完全齐全！可以启动训练！")
elif total > 0:
    print(f"[统计] ⚠️  缺 {10000-total} 个")
else:
    print("[统计] ❌ 仍为空，请检查")
PYEOF

echo "[$(date '+%H:%M:%S')] ✅ 脚本执行完毕"
echo "videos/ 当前: $(find "$VID_DIR" -name '*.mp4' | wc -l) / 10000"

#!/bin/bash
set -e

VID_DIR="/root/autodl-tmp/CLIP_prefix_caption/Detic/1-1代码路径/大论文-视频字幕生成专项_BLIP-2_for_Video/00.数据集/msrvtt/videos"
TMP_DIR="/root/autodl-tmp/CLIP_prefix_caption/Detic/1-1代码路径/大论文-视频字幕生成专项_BLIP-2_for_Video/00.数据集/msrvtt_odl_tmp"
mkdir -p "$VID_DIR" "$TMP_DIR"

echo "[$(date '+%H:%M:%S')] ▶ OpenDataLab 下载 MSR-VTT 视频..."

python3 << 'PYEOF'
import os, sys, glob, shutil

TMP_DIR = "/root/autodl-tmp/CLIP_prefix_caption/Detic/1-1代码路径/大论文-视频字幕生成专项_BLIP-2_for_Video/00.数据集/msrvtt_odl_tmp"
VID_DIR = "/root/autodl-tmp/CLIP_prefix_caption/Detic/1-1代码路径/大论文-视频字幕生成专项_BLIP-2_for_Video/00.数据集/msrvtt/videos"

try:
    from openxlab.dataset import get
    print("[下载] openxlab.dataset.get 可用，开始下载...")
    get(dataset_repo='OpenDataLab/MSR-VTT', target_path=TMP_DIR)
    print("[下载] ✅ 下载完成")
except ImportError:
    print("[下载] ❌ openxlab 未安装")
    sys.exit(1)
except Exception as e:
    print(f"[下载] ❌ 失败: {e}")
    sys.exit(1)

# 找 zip 并解压
zips = glob.glob(os.path.join(TMP_DIR, "**", "*.zip"), recursive=True)
print(f"\n[解压] 找到 {len(zips)} 个 zip 文件")
for z in zips:
    print(f"[解压] {os.path.basename(z)} ...")
    import zipfile
    with zipfile.ZipFile(z, 'r') as zf:
        zf.extractall(TMP_DIR)
    print(f"[解压] ✅ 完成")

# 找 mp4 整理到 videos/
mp4s = glob.glob(os.path.join(TMP_DIR, "**", "*.mp4"), recursive=True)
print(f"\n[整理] 找到 {len(mp4s)} 个 mp4")

moved, skipped = 0, 0
for src in sorted(mp4s):
    fname = os.path.basename(src)
    dst = os.path.join(VID_DIR, fname)
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
print(f"\n[统计] 移动 {moved}，跳过 {skipped}，videos/ 共 {total}/10000 个 mp4")
if total == 10000:
    print("[统计] 🎉 视频完全齐全！")
elif total > 0:
    print(f"[统计] ⚠️  缺 {10000-total} 个")
else:
    print("[统计] ❌ 仍为空，打印目录结构：")
    for r, d, files in os.walk(TMP_DIR):
        depth = r.replace(TMP_DIR, "").count(os.sep)
        if depth > 4:
            continue
        print("  " * depth + os.path.basename(r) + "/")
        for f in files[:5]:
            print("  " * (depth+1) + f)
PYEOF

echo "[$(date '+%H:%M:%S')] ✅ 脚本执行完毕"
echo "当前 videos/ 数量: $(find "$VID_DIR" -name '*.mp4' | wc -l) / 10000"

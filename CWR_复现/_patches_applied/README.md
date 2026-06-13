# 已应用的代码补丁清单（针对 vtimellm 环境下的 lavis）

下列原文件已被"最小化重写"，原内容备份在本目录的 `_bak_*.py` 中。
要回滚到原版：把对应 `_bak_*.py` 复制回去即可。

| 路径 | 改动 |
|---|---|
| `lavis/__init__.py` | 砍掉旧版"启动时 import 全部模型/任务"逻辑，仅保留 registry path 注册 |
| `lavis/models/__init__.py` | 仅 import BLIP-2 系列 + 工具类 (BaseModel/XBertLMHeadDecoder/VisionTransformerEncoder) |
| `lavis/models/blip2_models/__init__.py` | 移除对 blip_models / albef 的旁路引用 |
| `lavis/tasks/__init__.py` | 仅保留 captioning + image/video pretrain |
| `lavis/runners/__init__.py` | 仅保留 RunnerBase / RunnerIter |

# 新增的 stub（不是改动原文件，而是补一个最小依赖）
| 路径 | 作用 |
|---|---|
| `lavis/models/blip_models/__init__.py` | 占位包 |
| `lavis/models/blip_models/blip_outputs.py` | 提供 `BlipOutput / BlipOutputFeatures / BlipSimilarity / BlipIntermediateOutput / BlipOutputWithLogits` 5 个 dataclass，仅供 `blip2_qformer.py:22` 旁路 import 使用 |

# 清掉所有 __pycache__（多次确认无残留 .pyc）

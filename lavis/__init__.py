# [CWR_复现] 重写 lavis/__init__.py: 保持 registry path 注册 + 简化 import
import os, sys
from omegaconf import OmegaConf

from lavis.common.registry import registry

__version__ = "1.0.1"

root_dir = os.path.dirname(os.path.abspath(__file__))
default_cfg = OmegaConf.load(os.path.join(root_dir, "configs/default.yaml"))

registry.register_path("library_root", root_dir)
repo_root = os.path.join(root_dir, "..")
registry.register_path("repo_root", repo_root)
cache_root = os.path.join(repo_root, default_cfg.env.cache_root)
registry.register_path("cache_root", cache_root)

registry.register("MAX_INT", sys.maxsize)
registry.register("SPLIT_NAMES", ["train", "val", "test"])

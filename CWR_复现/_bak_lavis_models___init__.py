# [CWR_复现] 重写: 只保留本仓库实际存在的子模块, 其它(albef/blip/clip/coca/...)全部不再 import
import logging
import torch

from omegaconf import OmegaConf

from lavis.common.registry import registry

from lavis.models.base_model import BaseModel
from lavis.models.blip2_models.blip2 import Blip2Base
from lavis.models.blip2_models.blip2_opt import Blip2OPT
from lavis.models.blip2_models.blip2_t5 import Blip2T5
from lavis.models.blip2_models.blip2_qformer import Blip2Qformer
from lavis.models.blip2_models.blip2_image_text_matching import Blip2ITM
from lavis.models.blip2_models.blip2_t5_instruct import Blip2T5Instruct
from lavis.models.blip2_models.blip2_vicuna_instruct import Blip2VicunaInstruct
from lavis.models.med import XBertLMHeadDecoder
from lavis.models.vit import VisionTransformerEncoder

__all__ = [
    "BaseModel",
    "Blip2Base", "Blip2OPT", "Blip2T5",
    "Blip2Qformer", "Blip2ITM",
    "Blip2T5Instruct", "Blip2VicunaInstruct",
    "XBertLMHeadDecoder", "VisionTransformerEncoder",
]


def load_model(name, model_type, is_eval=False, device="cpu", checkpoint=None):
    model = registry.get_model_class(name).from_pretrained(model_type=model_type)
    if checkpoint is not None:
        model.load_checkpoint(checkpoint)
    if is_eval:
        model.eval()
    if device == "cpu":
        model = model.float()
    return model.to(device)


def load_preprocess(config):
    """与官方一致，简化版"""
    from lavis.processors.base_processor import BaseProcessor

    def _build_proc_from_cfg(cfg):
        return (registry.get_processor_class(cfg.name).from_config(cfg)
                if cfg is not None else BaseProcessor())

    vis_processors = {"train": BaseProcessor(), "eval": BaseProcessor()}
    txt_processors = {"train": BaseProcessor(), "eval": BaseProcessor()}

    vis_proc_cfg = config.get("vis_processor")
    txt_proc_cfg = config.get("text_processor")
    if vis_proc_cfg is not None:
        vis_processors["train"] = _build_proc_from_cfg(vis_proc_cfg.get("train"))
        vis_processors["eval"]  = _build_proc_from_cfg(vis_proc_cfg.get("eval"))
    if txt_proc_cfg is not None:
        txt_processors["train"] = _build_proc_from_cfg(txt_proc_cfg.get("train"))
        txt_processors["eval"]  = _build_proc_from_cfg(txt_proc_cfg.get("eval"))
    return vis_processors, txt_processors


def load_model_and_preprocess(name, model_type, is_eval=False, device="cpu"):
    model_cls = registry.get_model_class(name)
    model = model_cls.from_pretrained(model_type=model_type)
    if is_eval:
        model.eval()
    cfg = OmegaConf.load(model_cls.default_config_path(model_type))
    if cfg is not None:
        preprocess_cfg = cfg.preprocess
        vis_processors, txt_processors = load_preprocess(preprocess_cfg)
    else:
        vis_processors, txt_processors = None, None
        logging.info(
            f"""No default preprocess for model {name} ({model_type}).
                This can happen if the model is not a pretrained model."""
        )
    if device == "cpu" or device == torch.device("cpu"):
        model = model.float()
    return model.to(device), vis_processors, txt_processors


class ModelZoo:
    def __init__(self) -> None:
        self.model_zoo = {
            k: list(v.PRETRAINED_MODEL_CONFIG_DICT.keys())
            for k, v in registry.mapping["model_name_mapping"].items()
        }

    def __str__(self) -> str:
        return ("=" * 50 + "\n"
                + f"{'Architectures':<30} {'Types'}\n" + "=" * 50 + "\n"
                + "\n".join(f"{name:<30} {', '.join(types)}"
                            for name, types in self.model_zoo.items()))

    def __iter__(self):
        return iter(self.model_zoo.items())

    def __len__(self):
        return sum(len(v) for v in self.model_zoo.values())


model_zoo = ModelZoo()

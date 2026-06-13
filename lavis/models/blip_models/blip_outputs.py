# [CWR_复现] stub: 复刻 BLIP 输出 dataclass，仅供 blip2_qformer 旁路 import 使用
from dataclasses import dataclass
from typing import Optional
import torch
from transformers.modeling_outputs import ModelOutput


@dataclass
class BlipSimilarity(ModelOutput):
    sim_i2t: Optional[torch.FloatTensor] = None
    sim_t2i: Optional[torch.FloatTensor] = None
    sim_i2t_m: Optional[torch.FloatTensor] = None
    sim_t2i_m: Optional[torch.FloatTensor] = None
    sim_i2t_targets: Optional[torch.FloatTensor] = None
    sim_t2i_targets: Optional[torch.FloatTensor] = None


@dataclass
class BlipIntermediateOutput(ModelOutput):
    image_embeds: Optional[torch.FloatTensor] = None
    text_embeds: Optional[torch.FloatTensor] = None
    image_embeds_m: Optional[torch.FloatTensor] = None
    text_embeds_m: Optional[torch.FloatTensor] = None
    encoder_output: Optional[torch.FloatTensor] = None
    encoder_output_neg: Optional[torch.FloatTensor] = None
    itm_logits: Optional[torch.FloatTensor] = None
    itm_labels: Optional[torch.LongTensor] = None
    decoder_output: Optional[torch.FloatTensor] = None
    decoder_labels: Optional[torch.LongTensor] = None


@dataclass
class BlipOutput(ModelOutput):
    sims: Optional[BlipSimilarity] = None
    intermediate_output: Optional[BlipIntermediateOutput] = None
    loss: Optional[torch.FloatTensor] = None
    loss_itc: Optional[torch.FloatTensor] = None
    loss_itm: Optional[torch.FloatTensor] = None
    loss_lm:  Optional[torch.FloatTensor] = None


@dataclass
class BlipOutputFeatures(ModelOutput):
    image_embeds: Optional[torch.FloatTensor] = None
    image_embeds_proj: Optional[torch.FloatTensor] = None
    text_embeds: Optional[torch.FloatTensor] = None
    text_embeds_proj: Optional[torch.FloatTensor] = None
    multimodal_embeds: Optional[torch.FloatTensor] = None


@dataclass
class BlipOutputWithLogits(BlipOutput):
    logits: Optional[torch.FloatTensor] = None
    logits_m: Optional[torch.FloatTensor] = None

#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
inference_helper.py - Helper del Modo 2 (HuggingFace) de llama-launcher.

Ejecuta inferencia textual o visual con modelos (vision-)lingüísticos de
HuggingFace que expongan la interfaz estándar de transformers
(AutoProcessor / AutoModelForCausalLM).

No está garantizado para todos los modelos multimodales: algunas arquitecturas
requieren código de generación específico o un adaptador de visión propio.

Uso:
    python inference_helper.py --model  "CARPETA_DEL_MODELO"
    python inference_helper.py --model  "CARPETA_DEL_MODELO" --prompt "Hola"
    python inference_helper.py --model  "CARPETA_DEL_MODELO" --image "foto.jpg"
    python inference_helper.py --model  "CARPETA_DEL_MODELO" --image "foto.jpg" --prompt "Describe"
"""

import argparse
import sys


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Inferencia textual/visual con modelos (vision-)lingüísticos "
                    "de HuggingFace que expongan AutoProcessor/AutoModelForCausalLM "
                    "(usado por llama-launcher)."
    )
    parser.add_argument("--model", required=True, help="Ruta o id HF del modelo")
    parser.add_argument("--prompt", default=None, help="Texto del prompt")
    parser.add_argument("--image", default=None, help="Ruta a la imagen (opcional)")
    return parser


def main() -> int:
    args = build_parser().parse_args()
    prompt = args.prompt if args.prompt else "Describe lo que ves"

    try:
        import torch  # noqa: F401
        from transformers import AutoModelForCausalLM, AutoProcessor, AutoTokenizer
    except ImportError as exc:  # pragma: no cover
        print(f"[ERROR] Dependencias faltantes: {exc}")
        print("        Instala con: pip install torch transformers pillow accelerate")
        return 1

    print(f"[INFO] Cargando modelo: {args.model}")

    # Los modelos multimodales modernos traen procesador propio. Si no existe,
    # se usa el tokenizer clásico (modelo de texto).
    processor = None
    try:
        processor = AutoProcessor.from_pretrained(args.model, trust_remote_code=True)
    except Exception:
        processor = None

    if processor is not None and args.image:
        from PIL import Image
        print(f"[INFO] Cargando imagen: {args.image}")
        image = Image.open(args.image).convert("RGB")
        text = processor.apply_chat_template(
            [{"role": "user", "content": prompt}],
            tokenize=False,
            add_generation_prompt=True,
        )
        inputs = processor(text=text, images=image, return_tensors="pt")
        model = AutoModelForCausalLM.from_pretrained(
            args.model,
            trust_remote_code=True,
            torch_dtype="auto",
            device_map="auto",
        )
        with torch.no_grad():
            out = model.generate(**inputs, max_new_tokens=512)
        print(processor.batch_decode(out[:, inputs["input_ids"].shape[1]:],
                                     skip_special_tokens=True)[0])
    else:
        tokenizer = AutoTokenizer.from_pretrained(args.model, trust_remote_code=True)
        model = AutoModelForCausalLM.from_pretrained(
            args.model,
            trust_remote_code=True,
            torch_dtype="auto",
            device_map="auto",
        )
        messages = [{"role": "user", "content": prompt}]
        text = tokenizer.apply_chat_template(
            messages, tokenize=False, add_generation_prompt=True
        )
        inputs = tokenizer(text, return_tensors="pt").to(model.device)
        with torch.no_grad():
            out = model.generate(**inputs, max_new_tokens=512)
        print(tokenizer.decode(out[0][inputs["input_ids"].shape[1]:],
                               skip_special_tokens=True))

    return 0


if __name__ == "__main__":
    sys.exit(main())

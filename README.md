# 🚀 llama-launcher

> Production-ready **Windows launcher** for **llama.cpp**, **OpenCode** and
> **local LLM inference**.

A single window to run local language models. No manual server commands needed —
just drag your model, answer a couple of questions, and in seconds you have an
OpenAI-compatible server running with **tool-calling** and **Jinja templates**
support, ready to plug into **OpenCode**.

---

## ✨ Features

- **Mode 1 — GGUF / llama-server**: serves any text `.gguf` with `llama-server.exe`
  on port **8080**, with:
  - Auto-detected or manually fixed **context** (`-c`).
  - **Multimodal** support via `mmproj` — but only for architectures that
    llama.cpp supports and *only if you provide a matching `mmproj` file* for
    the exact vision model (see below).
  - **Native Jinja** for tool-calling and stable streaming with OpenCode.
  - Automatic generation of the **`opencode.json`** config file.
  - Optional access from other devices on your network.
- **Mode 2 — Multimodal LLM**:
  - Via **GGUF** (`llama-mtmd-cli.exe`) for CPU.
  - Via **HuggingFace** (Python + transformers) using the `inference_helper.py`
    helper — for (vision-)language models exposing the standard
    `AutoProcessor` / `AutoModelForCausalLM` interface.
- **Drag & drop**: drop a `.txt` config file onto the window to launch the
  server directly with no questions.
- Remembers your **last run** (saves `last_launch.txt`).

---

## 📋 Requirements

| Component | Needed for | Details |
|---|---|---|
| **Windows** 10/11 | Everything | Native batch script |
| **llama.cpp (Windows build)** | Mode 1 | Download binaries from [llama.cpp releases](https://github.com/ggml-org/llama.cpp/releases) |
| **A `.gguf` model** | Mode 1 | Any compatible model (e.g. Gemma, Llama, Qwen, LLaVA) |
| **Python 3.10+** | Mode 2 (HuggingFace only) | Added to `PATH` |

> ⚠️ The script looks for **`llama-server.exe`** (and `llama-mtmd-cli.exe` in
> Mode 2-GGUF) **in the same folder** where it is placed. Put the llama.cpp
> binaries next to the script.

### Multimodal support — what actually works

`llama.cpp` can only handle **images** for a specific set of vision
architectures (e.g. LLaVA, Qwen-VL, Phi-3-vision) and only with a **matching
`mmproj.gguf`** file built for the exact same vision model. It is **not** a
generic image-understanding engine:

- **Mode 1 + Mode 2-GGUF**: if your model is *not* one of the supported vision
  architectures, or you don't have the correct `mmproj`, the model still runs
  as a normal **text** LLM — just don't pass an image or mmproj.
- **Mode 2-HuggingFace**: `inference_helper.py` uses transformers' standard
  `AutoProcessor` + `AutoModelForCausalLM`. It works out of the box with
  many modern (vision-)language models, but **not with every** multimodal
  architecture (some need custom generation code or a load_vision adapter).

---

## 🚀 Quick start

1. **Create a working folder** and copy into it:
   - `llama-launcher.bat` (this script)
   - the llama.cpp executables: `llama-server.exe` (and `llama-mtmd-cli.exe`
     if using Mode 2-GGUF) plus their DLLs
   - your `.gguf` model file

2. **Double-click** `llama-launcher.bat`.

3. Choose a mode:

   - **`1`** → llama-server server.
   - **`2`** → multimodal LLM inference.

---

## 🖱️ Using Mode 1 (server for OpenCode)

1. In the menu press **`1`**.
2. **Drag and drop** your `.gguf` model file (also accepts `.bin`, `.ggml`)
   onto the window and press Enter.
3. Answer:
   - Is it **multimodal**? If so, provide the `mmproj.gguf` path.
   - Is it an **instruct/chat** model? **Y** is recommended to enable Jinja and
     tool-calling. *(Default: Y)*.
   - **Context**: `0` for auto-detection, or a fixed value (e.g. `8192`, `16384`).
   - Allow **access from your WiFi network**? `Y` exposes the port to the LAN.
4. The script shows the parameters, generates `opencode.json` and starts
   `llama-server.exe` at `http://127.0.0.1:8080`.

> 💡 The first line of `last_launch.txt` and the alias name come from your model
> file name. You can **drag that `.txt` again** next time to relaunch with no
> questions.

### Connecting OpenCode

The script generates `opencode.json` with a `llamacpp` provider. To use it:

- **Local project**: copy `opencode.json` into your project, or
- **Global**: merge the `"provider"` block into
  `%USERPROFILE%\.config\opencode\opencode.json`.

Reference example (also included as `opencode.example.json`):

```json
{
  "$schema": "https://opencode.ai/config.json",
  "provider": {
    "llamacpp": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "llama.cpp (local)",
      "options": { "baseURL": "http://127.0.0.1:8080/v1" },
      "models": { "YOUR_MODEL": { "name": "YOUR_MODEL" } }
    }
  }
}
```

---

## 🖼️ Using Mode 2 (multimodal LLM)

Press **`2`** and provide the model path:

- **`.gguf`** → uses `llama-mtmd-cli.exe` (CPU). You can add `mmproj`, an image
  and a prompt. Image support only for llama.cpp vision architectures with a
  matching `mmproj` (see the multimodal note above).
- **HuggingFace folder** → uses Python + transformers via `inference_helper.py`.
  If `torch` is missing, the script installs it automatically. Works with models
  exposing a standard `AutoProcessor` / `AutoModelForCausalLM` interface (many
  modern VLMs); not guaranteed for every architecture.

---

## 📄 `.txt` config file format (drag & drop)

A 6-line file, one value per line, in this order:

```text
C:\folder\my-model-Instruct-q8_0.gguf   <- Line 1: model path
8192                                     <- Line 2: context (0 = auto)
127.0.0.1                                <- Line 3: host (0.0.0.0 = network)
                                         <- Line 4: mmproj path (empty = none)
Y                                        <- Line 5: Jinja (Y/N)
C:\folder\chat_template.jinja            <- Line 6: jinja template (empty = none)
```

Save it as `.txt`, **drag it** onto `llama-launcher.bat`, and the server will
start directly. There's an example template in `sample-config.txt`.

---

## 🛠️ Troubleshooting

| Problem | Solution |
|---|---|
| `No se encontro llama-server.exe` | Put the llama.cpp binary in the same folder as the script. |
| Generation "freezes" with context `0` | Models with 128k+ windows blow up RAM usage on CPU. Set a fixed context (e.g. `8192` or `16384`). |
| Model doesn't show up in OpenCode | Regenerate/verify your `opencode.json` and restart OpenCode. |
| Stream cuts off with OpenCode | Enable **Jinja (Y)** for stable tool-calling. |
| HuggingFace mode fails | Install: `pip install torch transformers pillow accelerate` |

---

## 🤝 Contributing

Want to improve it? Great!

1. *Fork* the repo and create a branch: `git checkout -b feature/new-feature`.
2. Make your changes and verify the `.bat` works on Windows.
3. Open a *pull request* describing the change.

---

## 📄 License

MIT — see the [LICENSE](LICENSE) file.

## 💡 Roadmap

- GPU support (`-ngl`), exposing the value as an option.
- Direct interactive chat mode (without OpenCode).
- Automatic context detection by reading the `.gguf` metadata.


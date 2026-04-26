# RunPod CUDA13 Python 3.13 Image

RunPod image for `amort_debug`.

## Base

- Ubuntu 24.04
- CUDA 13.0.2
- cuDNN devel
- Python 3.13 via uv
- PyTorch `>=2.10.0`
- NumPyro CUDA13

## Important

This image expects a host NVIDIA driver that supports CUDA 13.

For CUDA13/JAX/NumPyro, use a RunPod node with NVIDIA driver 580+.

## Runtime check

Inside the pod:

```bash
nvidia-smi
```

Then:

```bash
python - <<'PY'
import sys
import torch
import jax
import numpyro

print("python:", sys.version)
print("torch:", torch.__version__)
print("torch cuda:", torch.version.cuda)
print("torch cuda available:", torch.cuda.is_available())
print("torch device:", torch.cuda.get_device_name(0) if torch.cuda.is_available() else None)
print("jax:", jax.__version__)
print("jax devices:", jax.devices())
print("numpyro:", numpyro.__version__)
PY
```

## Image

```text
ghcr.io/joohwanko/runpod_docker:cuda13-py313
```

## Notes

This repository only builds the RunPod environment image.

The actual training repository, for example `amort_mar_30`, should be cloned or rsynced into `/workspace` after the pod starts.

"""Dựng mô hình bằng Blender không giao diện và xuất .glb vào assets/models/.

Cách chạy (cần module bpy: `pip install bpy`, Python 3.13):
    python tools/blender/build_models.py            # dựng tất cả
    python tools/blender/build_models.py enm_raider_skiff
Tệp .glb dùng được ngay trong Godot; họa sĩ mở lại bằng Blender (File > Import > glTF) để chỉnh tiếp.
Quy ước toạ độ và màu đỉnh: xem tools/blender/kit.py.
"""
import importlib
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(HERE, "models"))

import kit  # noqa: E402

MODELS = ["enm_raider_skiff"]
OUT = os.path.normpath(os.path.join(HERE, "..", "..", "assets", "models"))


def main(names):
    os.makedirs(OUT, exist_ok=True)
    for name in names or MODELS:
        kit.reset_scene()
        module = importlib.import_module(name)
        objects = module.build()
        path = os.path.join(OUT, name + ".glb")
        kit.export_glb(path, objects)
        print("OK", path, os.path.getsize(path), "bytes")


if __name__ == "__main__":
    main(sys.argv[1:])

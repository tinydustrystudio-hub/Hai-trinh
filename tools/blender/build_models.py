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

MODELS = ["enm_raider_skiff", "enm_ram_drone", "enm_spiked_crab", "twr_machine_gun", "twr_glue_sprayer", "twr_light_beam", "bld_wave_shield", "bld_repair_works", "bld_tidal_power", "bld_shipyard", "sat_radar_outpost", "sat_steel_depot", "sat_buoy_station", "sat_comms_tower"]
OUT = os.path.normpath(os.path.join(HERE, "..", "..", "assets", "models"))


def main(names):
    os.makedirs(OUT, exist_ok=True)
    for name in names or MODELS:
        kit.reset_scene()
        module = importlib.import_module(name)
        result = module.build()
        # build() trả về danh sách đối tượng (một tệp theo tên module) hoặc từ điển {tên tệp: [đối tượng]} (nhiều tệp, ví dụ đế và đầu nòng).
        outputs = result if isinstance(result, dict) else {name: result}
        for out_name, objects in outputs.items():
            path = os.path.join(OUT, out_name + ".glb")
            kit.export_glb(path, objects)
            print("OK", path, os.path.getsize(path), "bytes")


if __name__ == "__main__":
    main(sys.argv[1:])

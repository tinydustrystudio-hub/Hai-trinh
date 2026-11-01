"""Đưa một mô hình ngoài (từ Blender của bạn hoặc từ nền tảng AI tạo 3D) về đúng quy ước của game.

Chạy (cần `pip install bpy`, xem tools/blender/requirements.txt):
    python tools/blender/prepare_model.py INPUT.glb enm_ram_drone --length 2.8 --forward -z --max-tris 600

Làm gì:
  1. Nạp .glb/.gltf/.obj/.fbx, gộp mọi mesh thành một.
  2. Xoay cho MŨI (hoặc nòng súng) hướng −Z: --forward là trục mà mô hình gốc đang hướng mũi tới (mặc định -z; glTF thường là +z).
  3. Co về đúng chiều dài --length đơn vị Godot theo trục Z (1 ô = 4 đơn vị), đặt tâm x và z về 0, đáy ở độ cao --base-y.
  4. Giảm tam giác xuống không quá --max-tris (Decimate, giữ hình bóng).
  5. Nếu mô hình có texture: nướng màu texture vào màu đỉnh (--colors, mặc định bật) vì game dùng vật liệu màu đỉnh dùng chung
     (một lệnh vẽ cho cả 60 địch). Có --keep-texture để giữ nguyên vật liệu texture (tốn thêm lệnh vẽ; dùng cho mô hình ít, to).
  6. Xuất assets/models/<tên>.glb.

In ra số tam giác và kích thước cuối để đối chiếu với ngân sách trong docs/danh-sach-tai-nguyen-tam.md.
"""
import argparse
import math
import os
import sys

import bpy  # phải nạp trước bmesh
import bmesh  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import kit  # noqa: E402

OUT = os.path.normpath(os.path.join(HERE, "..", "..", "assets", "models"))
# Góc quay quanh trục đứng (Godot) để đưa hướng --forward về −Z. Hướng ghi theo toạ độ Godot sau khi nạp glTF.
YAW_FOR_FORWARD = {"-z": 0.0, "+z": math.pi, "-x": -math.pi / 2, "+x": math.pi / 2}


def import_any(path):
    ext = os.path.splitext(path)[1].lower()
    if ext in (".glb", ".gltf"):
        bpy.ops.import_scene.gltf(filepath=path)
    elif ext == ".obj":
        bpy.ops.wm.obj_import(filepath=path)
    elif ext == ".fbx":
        bpy.ops.import_scene.fbx(filepath=path)
    else:
        raise SystemExit("Định dạng chưa hỗ trợ: " + ext)


def join_meshes():
    meshes = [o for o in bpy.context.scene.objects if o.type == "MESH"]
    if not meshes:
        raise SystemExit("Không thấy mesh nào trong tệp")
    bpy.ops.object.select_all(action="DESELECT")
    for obj in meshes:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = meshes[0]
    for obj in meshes:  # bỏ quan hệ cha con để áp biến đổi
        obj.parent = None if obj.parent is None else obj.parent
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    if len(meshes) > 1:
        bpy.ops.object.join()
    return bpy.context.view_layer.objects.active


def bounds(obj):
    xs, ys, zs = [], [], []
    for v in obj.data.vertices:
        w = obj.matrix_world @ v.co
        xs.append(w.x)
        ys.append(w.y)
        zs.append(w.z)
    return (min(xs), max(xs)), (min(ys), max(ys)), (min(zs), max(zs))


def orient_and_fit(obj, forward, length, base_y):
    """Làm việc trong toạ độ Blender (z lên, mũi hướng +y tương ứng −z Godot)."""
    # Sau khi nhập glTF, Blender dùng z lên; trục Godot z -> Blender -y.
    yaw = YAW_FOR_FORWARD[forward]
    obj.rotation_euler = (0.0, 0.0, yaw)
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=False)
    (x0, x1), (y0, y1), (z0, z1) = bounds(obj)
    current = y1 - y0  # chiều dài theo trục Godot z là trục Blender y
    scale = length / current if current > 1e-6 else 1.0
    obj.scale = (scale, scale, scale)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    (x0, x1), (y0, y1), (z0, z1) = bounds(obj)
    obj.location = (-(x0 + x1) / 2, -(y0 + y1) / 2, base_y - z0)
    bpy.ops.object.transform_apply(location=True, rotation=False, scale=False)


def triangle_count(obj):
    obj.data.calc_loop_triangles()
    return len(obj.data.loop_triangles)


def decimate_to(obj, max_tris):
    tris = triangle_count(obj)
    if tris <= max_tris:
        return
    mod = obj.modifiers.new("Decimate", "DECIMATE")
    mod.ratio = max(max_tris / tris * 0.98, 0.01)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.modifier_apply(modifier=mod.name)


def bake_texture_to_vertex_colors(obj):
    """Lấy màu texture tại UV của từng góc mặt (nearest) ghi vào màu đỉnh; bỏ vật liệu."""
    mesh = obj.data
    image = None
    for slot in obj.material_slots:
        mat = slot.material
        if mat and mat.use_nodes:
            for node in mat.node_tree.nodes:
                if node.type == "TEX_IMAGE" and node.image:
                    image = node.image
                    break
        if image:
            break
    base = (0.7, 0.7, 0.7, 1.0)
    if image is None or not mesh.uv_layers:
        # Không có texture: lấy màu cơ bản của vật liệu đầu tiên.
        if obj.material_slots and obj.material_slots[0].material:
            c = obj.material_slots[0].material.diffuse_color
            base = (c[0], c[1], c[2], 1.0)
    width, height = image.size if image else (0, 0)
    pixels = list(image.pixels) if image else []
    uv = mesh.uv_layers.active.data if (image and mesh.uv_layers) else None
    layer = mesh.color_attributes.new("Color", "BYTE_COLOR", "CORNER")
    for loop in mesh.loops:
        if uv is not None and width:
            u, v = uv[loop.index].uv
            px = min(max(int(u % 1.0 * width), 0), width - 1)
            py = min(max(int(v % 1.0 * height), 0), height - 1)
            i = (py * width + px) * 4
            layer.data[loop.index].color = (pixels[i], pixels[i + 1], pixels[i + 2], 1.0)
        else:
            layer.data[loop.index].color = base
    mesh.color_attributes.active_color = layer
    mesh.materials.clear()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("input")
    parser.add_argument("name", help="tên tệp ra, ví dụ enm_ram_drone (không có .glb)")
    parser.add_argument("--length", type=float, required=True, help="chiều dài theo trục Z, đơn vị Godot")
    parser.add_argument("--forward", default="-z", choices=list(YAW_FOR_FORWARD), help="hướng mũi của mô hình gốc")
    parser.add_argument("--max-tris", type=int, default=600)
    parser.add_argument("--base-y", type=float, default=-0.1, help="độ cao của đáy mô hình so với mực nước")
    parser.add_argument("--keep-texture", action="store_true")
    args = parser.parse_args(sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else sys.argv[1:])
    kit.reset_scene()
    import_any(os.path.abspath(args.input))
    obj = join_meshes()
    orient_and_fit(obj, args.forward, args.length, args.base_y)
    decimate_to(obj, args.max_tris)
    if not args.keep_texture:
        bake_texture_to_vertex_colors(obj)
    obj.name = args.name
    for poly in obj.data.polygons:
        poly.use_smooth = False
    path = os.path.join(OUT, args.name + ".glb")
    os.makedirs(OUT, exist_ok=True)
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.export_scene.gltf(
        filepath=path, export_format="GLB", use_selection=True, export_apply=True, export_yup=True,
        export_normals=True, export_materials="EXPORT" if args.keep_texture else "NONE",
        export_vertex_color="ACTIVE", export_active_vertex_color_when_no_material=True)
    (x0, x1), (y0, y1), (z0, z1) = bounds(obj)
    print("OK", path)
    print("TRIS", triangle_count(obj), "SIZE x=%.2f y=%.2f z=%.2f (Godot: rộng, cao, dài)" % (x1 - x0, z1 - z0, y1 - y0))


if __name__ == "__main__":
    main()

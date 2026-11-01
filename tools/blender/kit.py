"""Bộ dựng hình khối cho Blender (chạy không giao diện bằng module `bpy`).

Toạ độ trong file này là toạ độ GODOT: x phải, y lên, z về phía người xem; mũi tàu và nòng súng hướng −z.
Hàm G() đổi sang trục Blender (z lên); bộ xuất glTF tự đổi lại về y lên, nên mô hình vào Godot đúng trục.
Màu tô bằng thuộc tính màu đỉnh (COLOR_0), cùng cách với MeshKit trong Godot, nên dùng chung vật liệu màu đỉnh.
"""
import math

import bpy  # phải nạp trước bmesh
import bmesh  # noqa: E402


def G(x, y, z):
    """Godot (x, y, z) -> Blender (x, -z, y)."""
    return (x, -z, y)


class Model:
    """Một mô hình: gom các khối vào một mesh duy nhất, có màu đỉnh."""

    def __init__(self, name):
        self.name = name
        self.bm = bmesh.new()
        self._face_colors = {}  # mặt -> (màu, màu mặt trên)

    # ---- khối cơ bản -------------------------------------------------
    def hull(self, points, color, top_color=None):
        """Vỏ lồi của các điểm (toạ độ Godot). Tiện cho thân tàu thon, mũi nhọn, khối vát."""
        verts = [self.bm.verts.new(G(*p)) for p in points]
        result = bmesh.ops.convex_hull(self.bm, input=verts, use_existing_faces=False)
        bmesh.ops.delete(self.bm, geom=result["geom_interior"], context="VERTS")
        faces = [g for g in result["geom"] if isinstance(g, bmesh.types.BMFace)]
        self.bm.faces.ensure_lookup_table()
        centroid = [sum(c) / len(points) for c in zip(*[G(*p) for p in points])]
        for face in faces:
            # Mặt phải hướng ra ngoài khối lồi; vỏ lồi của bmesh không bảo đảm chiều.
            face.normal_update()
            outward = [face.calc_center_median()[i] - centroid[i] for i in range(3)]
            if sum(face.normal[i] * outward[i] for i in range(3)) < 0:
                face.normal_flip()
            self._face_colors[face] = (color, top_color)
        return faces

    def box(self, center, size, color, top_color=None, yaw=0.0):
        cx, cy, cz = center
        hx, hy, hz = size[0] / 2, size[1] / 2, size[2] / 2
        c, s = math.cos(yaw), math.sin(yaw)
        pts = []
        for sx in (-1, 1):
            for sy in (-1, 1):
                for sz in (-1, 1):
                    lx, lz = sx * hx, sz * hz
                    pts.append((cx + lx * c + lz * s, cy + sy * hy, cz - lx * s + lz * c))
        return self.hull(pts, color, top_color)

    def prism(self, center, radius, y0, y1, sides, color, top_radius=None, top_color=None, yaw=0.0):
        """Trụ đa giác đứng (hoặc chóp cụt khi top_radius khác radius)."""
        cx, _, cz = center
        r1 = radius if top_radius is None else top_radius
        pts = []
        for i in range(sides):
            a = yaw + math.tau * i / sides
            pts.append((cx + math.cos(a) * radius, y0, cz + math.sin(a) * radius))
            pts.append((cx + math.cos(a) * r1, y1, cz + math.sin(a) * r1))
        if r1 == 0:
            pts = [p for p in pts if abs(p[1] - y1) > 1e-6] + [(cx, y1, cz)]
        return self.hull(pts, color, top_color)

    def finish(self):
        """Gộp thành đối tượng Blender có thuộc tính màu đỉnh và vật liệu màu đỉnh."""
        bm = self.bm
        mesh = bpy.data.meshes.new(self.name)
        layer = bm.loops.layers.color.new("Color")
        for face in bm.faces:
            color, top_color = self._face_colors.get(face, ((0.7, 0.7, 0.7), None))
            # Mặt hướng lên (theo pháp tuyến cuối cùng) dùng màu mặt trên.
            if top_color is not None and face.normal.z > 0.7:
                color = top_color
            # Bộ xuất glTF coi màu đỉnh là sRGB rồi đổi sang tuyến tính; bù lại để Godot nhận đúng giá trị mong muốn.
            rgba = (_to_srgb(color[0]), _to_srgb(color[1]), _to_srgb(color[2]), 1.0)
            for loop in face.loops:
                loop[layer] = rgba
        bm.to_mesh(mesh)
        bm.free()
        mesh.color_attributes.active_color = mesh.color_attributes["Color"]
        obj = bpy.data.objects.new(self.name, mesh)
        bpy.context.scene.collection.objects.link(obj)
        for poly in mesh.polygons:
            poly.use_smooth = False
        return obj


def _to_srgb(value):
    return value * 12.92 if value <= 0.0031308 else 1.055 * (value ** (1 / 2.4)) - 0.055


def reset_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def export_glb(path, objects):
    bpy.ops.object.select_all(action="DESELECT")
    for obj in objects:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = objects[0]
    bpy.ops.export_scene.gltf(
        filepath=path,
        export_format="GLB",
        use_selection=True,
        export_apply=True,
        export_yup=True,
        export_normals=True,
        export_materials="NONE",
        export_vertex_color="ACTIVE",
        export_active_vertex_color_when_no_material=True,
    )

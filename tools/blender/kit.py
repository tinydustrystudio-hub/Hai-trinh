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

    def box(self, center, size, color, top_color=None, yaw=0.0, chamfer=None):
        """Hộp (toạ độ Godot) xoay quanh trục đứng. chamfer: độ vát cạnh; None = tự chọn theo cỡ, 0 = không vát."""
        cx, cy, cz = center
        hx, hy, hz = size[0] / 2, size[1] / 2, size[2] / 2
        if chamfer is None:
            smallest = min(size)
            chamfer = min(0.04, smallest * 0.2) if smallest >= 0.3 else 0.0
        c, s = math.cos(yaw), math.sin(yaw)
        pts = []
        for sx in (-1, 1):
            for sy in (-1, 1):
                for sz in (-1, 1):
                    if chamfer > 0:
                        corner = [
                            (sx * hx, sy * (hy - chamfer), sz * (hz - chamfer)),
                            (sx * (hx - chamfer), sy * hy, sz * (hz - chamfer)),
                            (sx * (hx - chamfer), sy * (hy - chamfer), sz * hz),
                        ]
                    else:
                        corner = [(sx * hx, sy * hy, sz * hz)]
                    for lx, ly, lz in corner:
                        pts.append((cx + lx * c + lz * s, cy + ly, cz - lx * s + lz * c))
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

    def loft(self, stations, color, top_color=None):
        """Thân thon dựng từ các mặt cắt: stations = [(z, [(x, y), ...]), ...] (mỗi mặt cắt liệt kê đủ cả hai bên).
        Mỗi cặp mặt cắt liền kề là một vỏ lồi; ghép lại thành thân cong mượt (thân tàu, mai cua)."""
        faces = []
        for (za, pa), (zb, pb) in zip(stations, stations[1:]):
            pts = [(x, y, za) for x, y in pa] + [(x, y, zb) for x, y in pb]
            faces += self.hull(pts, color, top_color)
        return faces

    def lathe(self, profile, sides, color, top_color=None, center=(0.0, 0.0), scale=(1.0, 1.0), yaw=0.0, cap_bottom=True, cap_top=True):
        """Khối tròn xoay quanh trục đứng từ đường biên profile = [(bán kính, y), ...] đi từ dưới lên. Cho phép lõm (eo bồn, vai nón).
        scale = (x, z) ép dẹt mặt cắt thành elip (thân tàu tròn, mai cua)."""
        bm = self.bm
        cx, cz = center
        rings = []
        for r, y in profile:
            ring = []
            for i in range(sides):
                a = yaw + math.tau * i / sides
                ring.append(bm.verts.new(G(cx + math.cos(a) * r * scale[0], y, cz + math.sin(a) * r * scale[1])))
            rings.append(ring)
        faces = []
        for k in range(len(rings) - 1):
            lo, hi = rings[k], rings[k + 1]
            for i in range(sides):
                j = (i + 1) % sides
                if profile[k][0] <= 1e-6 and profile[k + 1][0] <= 1e-6:
                    continue
                quad = (hi[i], hi[j], lo[j], lo[i])
                try:
                    faces.append(bm.faces.new(quad))
                except ValueError:
                    pass  # mặt suy biến khi hai vòng trùng nhau (đỉnh nhọn)
        # Mặt đáy/nắp: quạt tam giác quanh tâm.
        def cap(ring, y, up):
            if profile[0][0] <= 0 and up is False:
                return
            centre = bm.verts.new(G(cx, y, cz))
            for i in range(sides):
                j = (i + 1) % sides
                tri = (centre, ring[j], ring[i]) if up else (centre, ring[i], ring[j])
                faces.append(bm.faces.new(tri))
        if cap_top and profile[-1][0] > 1e-6:
            cap(rings[-1], profile[-1][1], True)
        if cap_bottom and profile[0][0] > 1e-6:
            cap(rings[0], profile[0][1], False)
        # Gộp đỉnh trùng (đỉnh nhọn) để mặt không suy biến.
        bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-5)
        for f in faces:
            if f.is_valid:
                self._face_colors[f] = (color, top_color)
        return faces

    def ellipsoid(self, center, radii, sides, rings, color, top_color=None, yaw=0.0):
        """Elip khối (vỏ tròn, thân bầu): radii = (rx, ry, rz); dựng bằng lathe quanh trục đứng."""
        cx, cy, cz = center
        profile = []
        for k in range(rings + 1):
            t = math.pi * k / rings  # 0 = đáy, pi = đỉnh
            profile.append((math.sin(t) * 1.0, cy - math.cos(t) * radii[1]))
        return self.lathe(profile, sides, color, top_color, center=(cx, cz), scale=(radii[0], radii[2]), yaw=yaw)

    def tube(self, center, r0, r1, z0, z1, sides, color, end_color=None):
        """Ống (hoặc nón cụt) nằm dọc theo trục z (nòng súng, thấu kính, vòng): tâm (x, y), bán kính r0 ở z0 và r1 ở z1."""
        cx, cy = center[0], center[1]
        pts = []
        for i in range(sides):
            a = math.tau * i / sides
            pts.append((cx + math.cos(a) * r0, cy + math.sin(a) * r0, z0))
            pts.append((cx + math.cos(a) * r1, cy + math.sin(a) * r1, z1))
        return self.hull(pts, color, top_color=end_color)

    def ring(self, center, inner, outer, y0, y1, sides, color, yaw=0.0):
        """Vành đứng rỗng giữa hai bán kính (như MeshKit.ring): không nằm trong vỏ lồi nên dựng mặt tay."""
        cx, _, cz = center
        bm = self.bm
        ring_faces = []
        for i in range(sides):
            a0 = yaw + math.tau * i / sides
            a1 = yaw + math.tau * (i + 1) / sides
            c0, s0, c1, s1 = math.cos(a0), math.sin(a0), math.cos(a1), math.sin(a1)
            def v(r, y, c, s):
                return bm.verts.new(G(cx + c * r, y, cz + s * r))
            o0t, o1t = v(outer, y1, c0, s0), v(outer, y1, c1, s1)
            o0b, o1b = v(outer, y0, c0, s0), v(outer, y0, c1, s1)
            i0t, i1t = v(inner, y1, c0, s0), v(inner, y1, c1, s1)
            i0b, i1b = v(inner, y0, c0, s0), v(inner, y0, c1, s1)
            quads = [
                (o0t, o1t, o1b, o0b),  # ngoài
                (i1t, i0t, i0b, i1b),  # trong
                (i0t, i1t, o1t, o0t),  # mặt trên
                (o0b, o1b, i1b, i0b),  # mặt dưới
            ]
            for q in quads:
                f = bm.faces.new(q)
                ring_faces.append(f)
        for f in ring_faces:
            self._face_colors[f] = (color, None)
        return ring_faces

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
        normals = _smooth_corner_normals(bm)
        bm.to_mesh(mesh)
        bm.free()
        mesh.normals_split_custom_set(normals)
        mesh.color_attributes.active_color = mesh.color_attributes["Color"]
        obj = bpy.data.objects.new(self.name, mesh)
        bpy.context.scene.collection.objects.link(obj)
        for poly in mesh.polygons:
            poly.use_smooth = False
        return obj


SMOOTH_ANGLE = math.radians(50.0)


def _smooth_corner_normals(bm):
    """Pháp tuyến theo góc: mặt kề nhau lệch dưới SMOOTH_ANGLE thì chung pháp tuyến (trụ, bầu, cạnh vát tròn),
    lớn hơn thì giữ cạnh sắc (hộp). Trả về danh sách theo thứ tự các góc mặt."""
    limit = math.cos(SMOOTH_ANGLE)
    bm.normal_update()
    result = []
    for face in bm.faces:
        for loop in face.loops:
            total = face.normal.copy() * face.calc_area()
            for other in loop.vert.link_faces:
                if other is not face and other.normal.dot(face.normal) >= limit:
                    total += other.normal * other.calc_area()
            result.append(tuple(total.normalized()))
    return result


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

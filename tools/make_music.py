#!/usr/bin/env python3
"""Dựng bản nhạc nền tạm "Hải Trình – sóng ngoài khơi" cho tháng 1 (góp ý 3 của đạo diễn: có nhạc khi thử cho
đỡ nhàm chán). Không dùng mẫu âm thanh nào: mọi tiếng đều tổng hợp bằng công thức.

- 100 nhịp/phút, 16 ô nhịp 4/4 (38,4 giây), lặp liền mạch (đuôi tiếng cuối cộng vòng về đầu bài).
- Giai điệu ngũ cung La thứ (La Đô Rê Mi Sol), tiếng gảy kiểu đàn tranh có luyến từ dưới lên;
  từ ô 9 thêm chuỗi rải hợp âm nhỏ tiếng. Bass tròn, pad hợp âm êm, trống nhẹ.

Cách dùng (cần numpy và ffmpeg có libvorbis):
    python3 tools/make_music.py assets/audio/music_theme.ogg
"""
import os
import subprocess
import sys
import tempfile
import wave

import numpy as np

SR = 44100
BPM = 100.0
BEAT = 60.0 / BPM
BAR = BEAT * 4.0
BARS = 16
LENGTH = BAR * BARS
STEP = BEAT / 2.0  # nốt móc đơn

NOTE_INDEX = {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}


def freq(name: str) -> float:
    pitch = NOTE_INDEX[name[0]]
    rest = name[1:]
    if rest.startswith("#"):
        pitch += 1
        rest = rest[1:]
    octave = int(rest)
    midi = 12 * (octave + 1) + pitch
    return 440.0 * 2.0 ** ((midi - 69) / 12.0)


CHORDS = ["Am", "F", "C", "G", "Am", "F", "G", "Em", "F", "G", "Am", "Am", "F", "G", "C", "Em"]
CHORD_NOTES = {
    "Am": ["A2", "C4", "E4", "A4"],
    "F": ["F2", "A3", "C4", "F4"],
    "C": ["C3", "E4", "G4", "C5"],
    "G": ["G2", "B3", "D4", "G4"],
    "Em": ["E2", "G3", "B3", "E4"],
}
# Mỗi ô 8 móc đơn: tên nốt, "-" ngân tiếp, "." nghỉ.
MELODY = [
    "A4 . C5 D5 E5 - D5 C5",
    "C5 - A4 - G4 A4 C5 .",
    "E5 - G5 - E5 D5 C5 D5",
    "D5 - - - . G4 A4 C5",
    "E5 . E5 G5 A5 - G5 E5",
    "D5 - C5 D5 C5 A4 G4 A4",
    "G4 - A4 C5 D5 - E5 D5",
    "E5 - - - - . . .",
    "A5 - G5 E5 D5 - C5 D5",
    "D5 - G4 - A4 C5 D5 E5",
    "E5 - D5 C5 A4 - C5 D5",
    "E5 - - - . . G5 A5",
    "C6 - A5 - G5 E5 D5 -",
    "D5 E5 G5 - E5 D5 C5 -",
    "E5 - D5 C5 A4 - G4 -",
    "A4 - - - - . . .",
]


def envelope(n: int, attack: float, decay: float) -> np.ndarray:
    t = np.arange(n) / SR
    env = np.exp(-t / decay)
    a = max(int(attack * SR), 1)
    env[:a] *= np.linspace(0.0, 1.0, a)
    return env


def pluck(f: float, duration: float, glide: bool) -> np.ndarray:
    """Tiếng gảy: nhiều họa âm tắt nhanh dần theo bậc; có thể luyến từ dưới lên một cung."""
    n = int((duration + 1.6) * SR)
    t = np.arange(n) / SR
    pitch = np.full(n, f)
    if glide:
        g = int(0.09 * SR)
        pitch[:g] = f * 2.0 ** (np.linspace(-2.0, 0.0, g) / 12.0)
    phase = 2.0 * np.pi * np.cumsum(pitch) / SR
    out = np.zeros(n)
    for h, amp in enumerate([1.0, 0.55, 0.32, 0.2, 0.12, 0.07], start=1):
        out += amp * np.sin(phase * h) * np.exp(-t * (1.6 + h * 1.4))
    # Rung nhẹ cuối nốt (nhấn rung kiểu đàn tranh).
    out *= 1.0 + 0.04 * np.sin(2.0 * np.pi * 5.5 * t) * np.clip(t - 0.25, 0.0, 1.0)
    out *= envelope(n, 0.004, 10.0)
    return out


def bass(f: float, duration: float) -> np.ndarray:
    n = int((duration + 0.3) * SR)
    t = np.arange(n) / SR
    out = np.sin(2 * np.pi * f * t) + 0.35 * np.sin(4 * np.pi * f * t) + 0.12 * np.sin(6 * np.pi * f * t)
    env = envelope(n, 0.012, 0.9)
    env[int(duration * SR):] *= np.linspace(1.0, 0.0, n - int(duration * SR))
    return out * env


def pad(notes, duration: float) -> np.ndarray:
    n = int((duration + 0.8) * SR)
    t = np.arange(n) / SR
    out = np.zeros(n)
    for name in notes[1:]:
        f = freq(name)
        for detune in (-0.12, 0.12):
            out += np.sin(2 * np.pi * (f + detune) * t) * 0.5
            out += np.sin(4 * np.pi * (f + detune) * t) * 0.08
    env = np.ones(n)
    a = int(0.6 * SR)
    env[:a] = np.linspace(0.0, 1.0, a)
    r = n - int(duration * SR)
    env[-r:] *= np.linspace(1.0, 0.0, r)
    return out * env * (1.0 + 0.08 * np.sin(2 * np.pi * 0.5 * t))


def kick() -> np.ndarray:
    n = int(0.35 * SR)
    t = np.arange(n) / SR
    f = 45.0 + 75.0 * np.exp(-t * 28.0)
    return np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t * 11.0)


def noise_hit(rng, length: float, decay: float, bright: bool) -> np.ndarray:
    n = int(length * SR)
    t = np.arange(n) / SR
    x = rng.standard_normal(n)
    # Lọc thông cao đơn giản: hiệu hai mẫu kề nhau.
    x = np.diff(x, prepend=0.0) if bright else (x + np.roll(x, 1) + np.roll(x, 2)) / 3.0
    return x * np.exp(-t / decay)


def place(track: np.ndarray, sound: np.ndarray, start: float, gain: float) -> None:
    """Cộng sound vào track từ giây start; phần tràn qua cuối bài cộng vòng về đầu (lặp liền mạch)."""
    i = int(round(start * SR)) % len(track)
    end = i + len(sound)
    if end <= len(track):
        track[i:end] += sound * gain
    else:
        first = len(track) - i
        track[i:] += sound[:first] * gain
        track[: len(sound) - first] += sound[first:] * gain


def render() -> np.ndarray:
    rng = np.random.default_rng(31)
    track = np.zeros(int(round(LENGTH * SR)))
    for bar in range(BARS):
        t0 = bar * BAR
        chord = CHORD_NOTES[CHORDS[bar]]
        place(track, pad(chord, BAR), t0, 0.05)
        root = freq(chord[0])
        place(track, bass(root, BEAT * 1.5), t0, 0.28)
        place(track, bass(root, BEAT * 0.5), t0 + BEAT * 1.5, 0.18)
        place(track, bass(root * 1.5, BEAT * 1.5), t0 + BEAT * 2, 0.22)
        place(track, bass(root, BEAT * 0.5), t0 + BEAT * 3.5, 0.16)
        # Giai điệu.
        slots = MELODY[bar].split()
        for k, slot in enumerate(slots):
            if slot in ("-", "."):
                continue
            length = 1
            while k + length < len(slots) and slots[k + length] == "-":
                length += 1
            glide = (bar + k) % 3 == 0 and length >= 2
            place(track, pluck(freq(slot), length * STEP, glide), t0 + k * STEP, 0.24)
        # Chuỗi rải hợp âm nhỏ tiếng ở nửa sau bài.
        if bar >= 8:
            tones = chord[1:] + [chord[2]]
            for k in range(8):
                f = freq(tones[k % len(tones)]) * 2.0
                place(track, pluck(f, STEP, False), t0 + k * STEP + 0.01, 0.045)
        # Trống nhẹ: trống cái phách 1 và 3, tiếng gõ nhỏ phách 2 và 4, xóc móc đơn.
        for beat in range(4):
            if beat in (0, 2):
                place(track, kick(), t0 + beat * BEAT, 0.35)
            else:
                place(track, noise_hit(rng, 0.2, 0.05, False), t0 + beat * BEAT, 0.08)
        for k in range(8):
            accent = 0.03 if k % 2 == 0 else 0.018
            place(track, noise_hit(rng, 0.06, 0.012, True), t0 + k * STEP, accent)
    # Nén mềm rồi chuẩn hóa đỉnh về −3 dB.
    track = np.tanh(track * 1.4)
    track *= 10 ** (-3 / 20) / np.max(np.abs(track))
    return track


def main() -> None:
    out_path = sys.argv[1] if len(sys.argv) > 1 else "assets/audio/music_theme.ogg"
    samples = (render() * 32767).astype(np.int16)
    with tempfile.TemporaryDirectory() as tmp:
        wav_path = os.path.join(tmp, "music.wav")
        with wave.open(wav_path, "wb") as f:
            f.setnchannels(1)
            f.setsampwidth(2)
            f.setframerate(SR)
            f.writeframes(samples.tobytes())
        subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", wav_path, "-c:a", "libvorbis", "-q:a", "3", out_path], check=True)
    print("%s: %.1f giây" % (out_path, len(samples) / SR))


if __name__ == "__main__":
    main()

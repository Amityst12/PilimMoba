#!/usr/bin/env python3
"""Procedural 16-bit mono PCM WAV generator for Pilim MOBA sound effects."""

import math
import os
import random
import struct
import wave

SAMPLE_RATE = 44100
OUT_DIR = os.path.join(os.path.dirname(__file__), "..", "assets", "audio")


def write_wav(filename: str, samples: list[float]) -> None:
    os.makedirs(OUT_DIR, exist_ok=True)
    filepath = os.path.join(OUT_DIR, filename)
    with wave.open(filepath, "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SAMPLE_RATE)
        frames = bytearray()
        for s in samples:
            clamped = max(-1.0, min(1.0, s))
            val = int(clamped * 32767)
            frames.extend(struct.pack("<h", val))
        w.writeframes(frames)
    print(f"Generated: {filename} ({len(samples) / SAMPLE_RATE:.2f}s)")


def gen_click() -> list[float]:
    duration = 0.04
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        env = math.exp(-t * 90.0)
        s = math.sin(2 * math.pi * 1200 * t) * env
        samples.append(s * 0.6)
    return samples


def gen_hover() -> list[float]:
    duration = 0.025
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        env = math.exp(-t * 120.0)
        s = math.sin(2 * math.pi * 1600 * t) * env
        samples.append(s * 0.25)
    return samples


def gen_cast() -> list[float]:
    duration = 0.22
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        env = math.sin(math.pi * (i / num_samples))
        freq = 300 + 600 * (1.0 - t / duration)
        s = math.sin(2 * math.pi * freq * t) * 0.5
        noise = (random.random() * 2 - 1) * 0.3 * (1.0 - t / duration)
        samples.append((s + noise) * env * 0.7)
    return samples


def gen_hit() -> list[float]:
    duration = 0.12
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        env = math.exp(-t * 35.0)
        freq = 180 * math.exp(-t * 20.0)
        s = math.sin(2 * math.pi * freq * t) * 0.7
        noise = (random.random() * 2 - 1) * 0.4 * math.exp(-t * 40.0)
        samples.append((s + noise) * env * 0.8)
    return samples


def gen_explosion() -> list[float]:
    duration = 0.45
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        env = math.exp(-t * 8.0)
        freq = 90 * math.exp(-t * 6.0)
        s = math.sin(2 * math.pi * freq * t) * 0.6
        noise = (random.random() * 2 - 1) * 0.6 * math.exp(-t * 10.0)
        samples.append((s + noise) * env * 0.9)
    return samples


def gen_blink() -> list[float]:
    duration = 0.18
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        env = math.sin(math.pi * (i / num_samples))
        freq = 400 + 1400 * (t / duration)
        s = math.sin(2 * math.pi * freq * t) * 0.6
        s2 = math.sin(2 * math.pi * (freq * 1.5) * t) * 0.3
        samples.append((s + s2) * env * 0.7)
    return samples


def gen_levelup() -> list[float]:
    duration = 0.4
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    notes = [523.25, 659.25, 783.99, 1046.50]  # C5, E5, G5, C6
    note_len = duration / len(notes)
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        idx = min(int(t / note_len), len(notes) - 1)
        freq = notes[idx]
        note_t = t - idx * note_len
        env = math.exp(-note_t * 8.0) * (1.0 - t / (duration * 1.2))
        s = math.sin(2 * math.pi * freq * t) * 0.6 + math.sin(2 * math.pi * freq * 2 * t) * 0.2
        samples.append(s * env * 0.8)
    return samples


def gen_death() -> list[float]:
    duration = 0.5
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        env = math.exp(-t * 6.0)
        freq = 240 * (1.0 - t / duration * 0.6)
        s = math.sin(2 * math.pi * freq * t) * 0.6 + math.sin(2 * math.pi * (freq * 0.5) * t) * 0.3
        samples.append(s * env * 0.7)
    return samples


def gen_announce() -> list[float]:
    duration = 0.45
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        env = math.exp(-t * 7.0)
        s = (math.sin(2 * math.pi * 440 * t) + math.sin(2 * math.pi * 660 * t) + math.sin(2 * math.pi * 880 * t)) / 3.0
        samples.append(s * env * 0.8)
    return samples


def gen_victory() -> list[float]:
    duration = 1.2
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    notes = [523.25, 659.25, 783.99, 1046.50, 1318.51]  # C5, E5, G5, C6, E6
    step = 0.2
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        val = 0.0
        for n_idx, freq in enumerate(notes):
            start = n_idx * step
            if t >= start:
                local_t = t - start
                env = math.exp(-local_t * 3.5)
                val += (math.sin(2 * math.pi * freq * t) + math.sin(2 * math.pi * freq * 2 * t) * 0.25) * env * 0.25
        samples.append(min(1.0, max(-1.0, val * 0.9)))
    return samples


def gen_defeat() -> list[float]:
    duration = 1.2
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    notes = [440.0, 415.30, 392.0, 349.23]  # A4, Ab4, G4, F4
    step = 0.25
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        val = 0.0
        for n_idx, freq in enumerate(notes):
            start = n_idx * step
            if t >= start:
                local_t = t - start
                env = math.exp(-local_t * 3.0)
                val += (math.sin(2 * math.pi * freq * t) + math.sin(2 * math.pi * (freq * 0.5) * t) * 0.3) * env * 0.25
        samples.append(min(1.0, max(-1.0, val * 0.9)))
    return samples


def gen_gold() -> list[float]:
    duration = 0.22
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        val = 0.0
        env1 = math.exp(-t * 22.0)
        val += math.sin(2 * math.pi * 1800 * t) * env1 * 0.5
        if t > 0.07:
            env2 = math.exp(-(t - 0.07) * 20.0)
            val += math.sin(2 * math.pi * 2400 * (t - 0.07)) * env2 * 0.6
        samples.append(val * 0.8)
    return samples


def gen_buy() -> list[float]:
    duration = 0.25
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        env = math.exp(-t * 18.0)
        s = math.sin(2 * math.pi * 1400 * t) * 0.4 + math.sin(2 * math.pi * 2100 * t) * 0.3
        noise = (random.random() * 2 - 1) * 0.3 * math.exp(-t * 25.0)
        samples.append((s + noise) * env * 0.8)
    return samples


def gen_level_ability() -> list[float]:
    duration = 0.22
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        env = math.sin(math.pi * (i / num_samples))
        freq = 600 + 1200 * (t / duration)
        s = math.sin(2 * math.pi * freq * t) * 0.6
        samples.append(s * env * 0.7)
    return samples


def main():
    generators = {
        "click.wav": gen_click,
        "hover.wav": gen_hover,
        "cast.wav": gen_cast,
        "hit.wav": gen_hit,
        "explosion.wav": gen_explosion,
        "blink.wav": gen_blink,
        "levelup.wav": gen_levelup,
        "death.wav": gen_death,
        "announce.wav": gen_announce,
        "victory.wav": gen_victory,
        "defeat.wav": gen_defeat,
        "gold.wav": gen_gold,
        "buy.wav": gen_buy,
        "level_ability.wav": gen_level_ability,
    }
    for filename, gen in generators.items():
        write_wav(filename, gen())
    print(f"Successfully generated {len(generators)} audio files into {OUT_DIR}")


if __name__ == "__main__":
    main()

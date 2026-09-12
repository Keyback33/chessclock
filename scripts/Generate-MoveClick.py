"""Generate the original mechanical switch effect; no external audio assets.

Two damped impacts model the plunger and latch, with a short spring resonance.
Run from any directory with Python 3 (standard library only).
"""

import math
from pathlib import Path
import random
import struct
import wave


rate = 44100
duration = 0.115
rng = random.Random(1204)
samples = []
previous_noise = 0.0
for i in range(round(rate * duration)):
    t = i / rate
    noise = rng.uniform(-1, 1)
    transient = noise - previous_noise * 0.75
    previous_noise = noise
    value = 0.0
    for onset, gain in [(0.0, 1.0), (0.024, 0.65)]:
        age = t - onset
        if age < 0:
            continue
        attack = min(1.0, age / 0.0005)
        impact = transient * math.exp(-age / 0.0035) * 0.65
        body = math.sin(2 * math.pi * 780 * age) * math.exp(-age / 0.010) * 0.35
        spring = math.sin(2 * math.pi * 2310 * age) * math.exp(-age / 0.014) * 0.12
        value += gain * attack * (impact + body + spring)
    samples.append(value * min(1.0, (duration - t) / 0.008))

peak = max(abs(sample) for sample in samples)
pcm = b''.join(struct.pack('<h', round(sample / peak * 26000)) for sample in samples)
target = Path(__file__).resolve().parents[1] / 'assets/audio/move_click.wav'
target.parent.mkdir(parents=True, exist_ok=True)
with wave.open(str(target), 'wb') as output:
    output.setparams((1, 2, rate, 0, 'NONE', 'not compressed'))
    output.writeframes(pcm)
print(f'{target.name}: {len(samples) / rate:.3f} s, mono PCM 16-bit, {rate} Hz')

"""Original pentatonic greenhouse loop and soft, nonverbal plant sounds.

Only mathematical synthesis is used; there are no third-party samples.
Run with Python 3 from any directory to regenerate the shipped WAV assets.
"""
from pathlib import Path
import math
import struct
import wave

ROOT = Path(__file__).resolve().parents[1] / 'assets/seed_lab/audio'
ROOT.mkdir(parents=True, exist_ok=True)
RATE = 22050


def render(name, seconds, notes, loop=False):
    count = round(seconds * RATE)
    track = [0.0] * count
    for start, midi, duration, volume in notes:
        frequency = 440 * 2 ** ((midi - 69) / 12)
        for n in range(round(duration * RATE)):
            t = n / RATE
            envelope = min(1, t / .012) * math.exp(-t * 3.4)
            envelope *= min(1, (duration - t) / .08)
            tone = math.sin(math.tau * frequency * t)
            tone += .18 * math.sin(math.tau * frequency * 2 * t) * math.exp(-t * 3)
            tone += .055 * math.sin(math.tau * frequency * 3 * t)
            index = round(start * RATE) + n
            if loop:
                index %= count
            if index < count:
                track[index] += tone * envelope * volume
    peak = max(abs(x) for x in track) or 1
    gain = min(1, .65 / peak)
    with wave.open(str(ROOT / f'{name}.wav'), 'wb') as out:
        out.setparams((1, 2, RATE, 0, 'NONE', 'not compressed'))
        out.writeframes(b''.join(struct.pack('<h', round(x * gain * 32767)) for x in track))


beat = 60 / 86
# C-D-E-G-A: a quiet pentatonic melody, with plucked fifths underneath.
melody = [76, 79, 81, 79, 76, 74, 72, None,
          74, 76, 79, 76, 74, 72, 69, None,
          72, 76, 79, 84, 81, 79, 76, None,
          74, 76, 74, 72, 69, 67, 72, None]
notes = []
for i, pitch in enumerate(melody):
    if pitch is not None:
        notes.append((i * beat, pitch, 1.8, .23))
    if i % 4 == 0:
        notes.extend([(i * beat, 48 if i % 8 == 0 else 45, 2.5, .10),
                      ((i + 2) * beat, 67, 1.8, .075)])
render('garden', beat * 32, notes, loop=True)
render('grow', 3.8, [(i * .33, p, 1.0, .22)
                    for i, p in enumerate([48, 55, 60, 64, 67, 72, 76, 79, 84])])
render('bloom', 2.0, [(i * .10, p, 1.2, .21)
                     for i, p in enumerate([72, 76, 79, 84, 88])])
render('sing', 1.8, [(i * .20, p, .65, .25)
                    for i, p in enumerate([79, 81, 79, 76, 72, 76])])
render('pop', .75, [(0, 79, .35, .31), (.12, 84, .4, .24), (.25, 88, .4, .14)])
print('Generated five original seed lab sounds.')

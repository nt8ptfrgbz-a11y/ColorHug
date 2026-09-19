"""Original low pentatonic fantasy ambience and spirit interaction sounds.

Only mathematical synthesis is used; there are no third-party samples.
Run with Python 3 from any directory to regenerate the shipped WAV assets.
"""
from pathlib import Path
import math
import struct
import wave

ROOT = Path(__file__).resolve().parents[1] / 'assets/shanhai/audio'
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


beat = 60 / 64
melody = [64, None, 67, 69, 72, None, 69, 67, 64, None, 62, 60, 62, None, 64, None,
          67, None, 72, 76, 74, 72, 69, None, 67, 64, 62, None, 60, None, None, None]
notes = []
for i, pitch in enumerate(melody):
    if pitch is not None:
        notes.append((i * beat, pitch, 3.4, .18))
    if i % 4 == 0:
        notes.append((i * beat, 36 if i % 8 == 0 else 43, 4.5, .09))
        notes.append(((i + 2) * beat, 55, 2.9, .06))
render('realm', beat * 32, notes, loop=True)
render('awaken', 5.5, [(i * .40, p, 2.2, .22) for i, p in enumerate([36, 43, 48, 52, 55, 60, 64, 67, 72, 76])])
render('seal', .9, [(0, 79, .8, .25), (.08, 84, .75, .15)])
render('pet', 1.4, [(0, 60, 1, .19), (.2, 64, 1, .17), (.4, 67, .9, .13)])
render('feed', 1.8, [(i * .13, p, .8, .22) for i, p in enumerate([67, 72, 76, 79, 84])])
render('takeoff', 2.5, [(i * .14, p, 1.2, .18) for i, p in enumerate([48, 55, 60, 64, 67, 72, 79, 84])])
render('chime', .8, [(0, 84, .7, .28), (.1, 91, .6, .16)])
render('arrival', 3, [(i * .16, p, 1.9, .19) for i, p in enumerate([60, 64, 67, 72, 76, 79, 84])])
print('Generated eight original Shanhai sounds.')

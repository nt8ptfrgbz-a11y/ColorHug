"""Original seamless, quiet music-box waltz for Little Wardrobe. No samples."""
from pathlib import Path
import math
import struct
import wave

root = Path(__file__).resolve().parents[1] / 'assets/dress_up/audio'
root.mkdir(parents=True, exist_ok=True)
rate = 22050
beat = 60 / 76
length = round(48 * beat * rate)
left, right = [0.0] * length, [0.0] * length

def note(start, midi, amplitude, pan=.5, seconds=2.2):
    hz = 440 * 2 ** ((midi - 69) / 12)
    for n in range(round(seconds * rate)):
        t = n / rate
        envelope = min(1, t / .018) * math.exp(-t * 3.1) * min(1, (seconds - t) / .12)
        tone = math.sin(math.tau * hz * t) + .13 * math.sin(math.tau * 2 * hz * t) * math.exp(-t * 2)
        sample = tone * envelope * amplitude
        i = (round(start * rate) + n) % length
        left[i] += sample * math.sqrt(1 - pan)
        right[i] += sample * math.sqrt(pan)
        echo = (i + round(.23 * rate)) % length
        left[echo] += sample * .09 * math.sqrt(pan)
        right[echo] += sample * .09 * math.sqrt(1 - pan)

chords = [(48,52,55),(53,57,60),(57,60,64),(55,59,62), (48,52,55),(53,57,60),(55,59,62),(48,52,55)]
melody = [[76,79,72],[77,None,76],[76,81,79],[74,None,71],[72,76,79],[77,76,74],[74,79,71],[72,None,None]]
for bar in range(16):
    chord = chords[bar % 8]
    start = bar * 3 * beat
    note(start, chord[0], .13, .5)
    for i in range(2):
        note(start + (i + 1) * beat, chord[i + 1] + 12, .065, .25 + i*.5)
    for i, pitch in enumerate(melody[bar % 8]):
        if pitch is not None:
            note(start + i * beat, pitch + (12 if bar >= 8 else 0), .105 if bar >= 8 else .14, .46)
peak = max(max(map(abs,left)), max(map(abs,right)))
gain = min(1, .45 / peak)
with wave.open(str(root / 'wardrobe_waltz.wav'), 'wb') as output:
    output.setparams((2,2,rate,0,'NONE','not compressed'))
    output.writeframes(b''.join(struct.pack('<hh',round(a*gain*32767),round(b*gain*32767)) for a,b in zip(left,right)))
print(f'Original loop: {length/rate:.2f}s, peak {peak*gain:.3f}')

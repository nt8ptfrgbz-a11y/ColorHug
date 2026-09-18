"""Original Silly Town sound design. Deterministic stereo PCM, no external assets.

Soft marimba / pizzicato score at 88 BPM, with a seamless 8-bar loop. All effects
have short attack/release envelopes and conservative peaks for small speakers.
"""
from pathlib import Path
import math
import random
import struct
import wave

OUT = Path(__file__).resolve().parent.parent / 'assets/silly_town/audio'
OUT.mkdir(parents=True, exist_ok=True)
SR = 22050
RNG = random.Random(20260917)

def write(name, left, right=None, peak=.65):
    right = right if right is not None else left
    maximum = max(max(map(abs, left)), max(map(abs, right)), .0001)
    gain = min(1, peak / maximum)
    with wave.open(str(OUT / f'{name}.wav'), 'wb') as f:
        f.setnchannels(2)
        f.setsampwidth(2)
        f.setframerate(SR)
        buf = bytearray()
        for a, b in zip(left, right):
            buf.extend(struct.pack('<hh', int(a * gain * 32767), int(b * gain * 32767)))
        f.writeframes(buf)

def effect(name, duration, fn):
    values = []
    for i in range(int(SR * duration)):
        t = i / SR
        u = t / duration
        envelope = min(1, t / .009) * min(1, (duration - t) / .035)
        values.append(fn(t, u) * envelope * .46)
    write(name, values)

S = math.sin
P = math.pi * 2
effect('pick', .19, lambda t,u: S(P*(560*t+700*t*t))*math.exp(-15*t))
effect('pop', .25, lambda t,u: S(P*(650*t-700*t*t))*math.exp(-18*t))
effect('boing', .55, lambda t,u: (S(P*(160*t+35*S(12*t)))+.16*S(P*660*t))*math.exp(-6*t))
effect('bubble', .48, lambda t,u: S(P*(400*t+90*t*t))*(.65+.35*S(39*t))*math.exp(-5*t))
effect('giggle', .72, lambda t,u: (S(P*(320*t+7*S(t*16)))+.24*S(P*640*t))*max(0,S(P*5*t))**2*math.exp(-1.7*t))
effect('slurp', .63, lambda t,u: S(P*(170*t+220*t*t))*(.6+.4*S(89*t))*math.exp(-3*t))
effect('crunch', .36, lambda t,u: RNG.uniform(-1,1)*(.25+.75*max(0,S(90*t)))*math.exp(-12*t))
effect('splash', .65, lambda t,u: (RNG.uniform(-1,1)*.3+S(P*(720*t-260*t*t))*.35)*math.exp(-5*t))
effect('marimba', .65, lambda t,u: (S(P*523.25*t)+.2*S(P*1569.75*t)*math.exp(-10*t))*math.exp(-7*t))
effect('bell', 1.1, lambda t,u: (S(P*659.25*t)+.18*S(P*1318.5*t))*math.exp(-4*t))
effect('pluck', .7, lambda t,u: (S(P*783.99*t)+.2*S(P*1567.98*t))*math.exp(-8*t))
effect('chime', 1.0, lambda t,u: (S(P*1046.5*t)+.24*S(P*1567.98*t))*math.exp(-5*t))

def midi(n): return 440 * 2 ** ((n-69)/12)
def add_note(left, right, start, note, duration, amplitude=.12, pan=.5, loop=False, bass=False):
    hz = midi(note)
    for k in range(int(duration*SR)):
        t = k / SR
        a = min(1,t/.012)*math.exp(-t*(3.8 if bass else 5.2))
        value = amplitude * a * (S(P*hz*t)+.19*S(P*hz*2*t)*math.exp(-t*4)+.07*S(P*hz*3*t))
        index = int(start*SR)+k
        if loop: index %= len(left)
        if index >= len(left): break
        left[index] += value * math.sqrt(1-pan)
        right[index] += value * math.sqrt(pan)

beat = 60/88
duration = 32*beat
left = [0.] * round(duration*SR)
right = left.copy()
chords = [(48,52,55), (53,57,60), (55,59,62), (48,52,55), (57,60,64), (53,57,60), (55,59,62), (48,52,55)]
melodies = [[72,None,76,79,76,None,74,None], [77,None,76,None,72,74,76,None], [74,None,79,None,77,74,None,None], [76,None,74,72,None,None,67,None], [76,None,81,None,79,76,72,None], [77,None,76,74,72,None,69,None], [74,None,71,None,74,79,None,None], [76,None,74,None,72,None,None,None]]
for bar,chord in enumerate(chords):
    start=bar*4*beat
    add_note(left,right,start,chord[0]-12,2*beat,.12,.5,True,True)
    add_note(left,right,start+2*beat,chord[0]-5,2*beat,.09,.5,True,True)
    for j in range(4):
        add_note(left,right,start+(j+.5)*beat,chord[j%3]+12,.6,.055,.25 if j%2 else .75,True)
    for j,note in enumerate(melodies[bar]):
        if note: add_note(left,right,start+j*.5*beat,note,.85,.16,.42+(j%3)*.08,True)
write('town_loop', left, right, peak=.5)

left=[0.] * (SR*3)
right=left.copy()
for i,note in enumerate([72,76,79,84,79,84]):
    add_note(left,right,.05+i*.19,note,1.3,.23,.35+i*.05)
write('celebrate',left,right)
print(f'Generated {len(list(OUT.glob("*.wav")))} original stereo assets in {OUT}')

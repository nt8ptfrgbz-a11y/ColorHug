"""Original, deterministic toy sound effects; no external recordings."""
import math, random, struct, wave
from pathlib import Path
ROOT = Path(__file__).resolve().parent.parent / 'assets/audio'
random.seed(18)
for name, duration in [('bounce', .32), ('snip', .18), ('splash', .45), ('horn', .38), ('squish', .38), ('drum', .24), ('bell', .65), ('frog', .40), ('cat', .48)]:
    rate = 22050
    samples = []
    for i in range(int(duration * rate)):
        t = i / rate
        u = t / duration
        env = min(1, u * 35) * (1-u)**2
        if name == 'bounce': v = math.sin(2*math.pi*(650*t-500*t*t))
        elif name == 'snip': v = random.uniform(-1,1) * (.5+.5*math.sin(2*math.pi*40*t))
        elif name == 'splash': v = .6*random.uniform(-1,1)+.4*math.sin(2*math.pi*(800*t-300*t*t))
        elif name == 'horn': v = .6*math.sin(2*math.pi*330*t)+.4*math.sin(2*math.pi*440*t)
        elif name == 'squish': v = math.sin(2*math.pi*(160*t+100*t*t))*(.5+.5*math.sin(2*math.pi*13*t))
        elif name == 'drum': v = .8*math.sin(2*math.pi*(130*t-150*t*t))+.2*random.uniform(-1,1)
        elif name == 'bell': v = .6*math.sin(2*math.pi*880*t)+.25*math.sin(2*math.pi*1760*t)+.15*math.sin(2*math.pi*2361*t)
        elif name == 'frog': v = math.sin(2*math.pi*(155*t+20*math.sin(t*15)))*(.5+.5*math.sin(2*math.pi*22*t))
        else: v = .7*math.sin(2*math.pi*(520*t-210*t*t))+.3*math.sin(2*math.pi*(1040*t-420*t*t))
        samples.append(int(max(-1,min(1,v*env*.25))*32767))
    with wave.open(str(ROOT / f'play_{name}.wav'), 'wb') as f:
        f.setnchannels(1); f.setsampwidth(2); f.setframerate(rate)
        f.writeframes(struct.pack('<'+'h'*len(samples), *samples))

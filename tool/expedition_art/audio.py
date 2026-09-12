"""Original quiet Foley-like toy sounds, generated offline."""
import math, random, struct, wave
from pathlib import Path
r=random.Random(36)
root=Path(__file__).resolve().parents[2]/'assets/audio'
for name,dur in [('engine',.5),('grab',.3),('wood',.35),('splash',.65),('echo',1.0),('dino',.65),('home',1.25)]:
    rate=22050; data=[]
    for i in range(int(dur*rate)):
        t=i/rate;u=t/dur;env=min(1,u*25)*(1-u)**2
        if name=='engine':v=(math.sin(2*math.pi*82*t)+.35*math.sin(2*math.pi*164*t))*(.7+.3*math.sin(t*50))*.5
        elif name=='grab':v=.45*math.sin(2*math.pi*(410*t-220*t*t))+.18*r.uniform(-1,1)
        elif name=='wood':v=math.sin(2*math.pi*180*t)*math.exp(-t*12)+.35*math.sin(2*math.pi*470*t)*math.exp(-t*25)
        elif name=='splash':v=r.uniform(-1,1)*.7+.2*math.sin(2*math.pi*(900*t-600*t*t))
        elif name=='echo':v=sum(.7**j*math.sin(2*math.pi*440*(t-j*.2))*math.exp(-(t-j*.2)*17) for j in range(4) if t>=j*.2)
        elif name=='dino':v=.7*math.sin(2*math.pi*(240*t+90*t*t))*(.6+.4*math.sin(t*18))+.15*math.sin(2*math.pi*720*t)
        else:
            notes=[392,493.88,587.33,783.99];k=min(3,int(t/.23));v=.6*math.sin(2*math.pi*notes[k]*t)*math.exp(-(t-k*.23)*6)
        data.append(int(max(-.95,min(.95,v*env*.24))*32767))
    with wave.open(str(root/f'expedition_{name}.wav'),'wb') as f:
        f.setnchannels(1);f.setsampwidth(2);f.setframerate(rate);f.writeframes(struct.pack('<'+'h'*len(data),*data))

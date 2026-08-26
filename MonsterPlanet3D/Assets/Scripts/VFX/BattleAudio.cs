using System;
using UnityEngine;

namespace MonsterPlanet3D.VFX
{
    public sealed class BattleAudio : MonoBehaviour
    {
        private const int SampleRate = 44100;

        [SerializeField, Range(0f, 1f)] private float masterVolume = 0.72f;

        private AudioClip _whoosh;
        private AudioClip _impact;
        private AudioClip _heavyImpact;
        private AudioClip _jump;
        private AudioClip _dodge;
        private AudioClip _charge;
        private AudioClip _beam;
        private AudioClip _warning;
        private AudioClip _perfectDodge;
        private AudioClip _pickup;

        private void Awake()
        {
            _whoosh = Synthesize("Energy whoosh", 0.22f, (t, random) =>
            {
                var envelope = Mathf.Sin(Mathf.PI * t);
                var noise = (float)(random.NextDouble() * 2.0 - 1.0);
                return (Mathf.Sin(t * t * 150f) * 0.42f + noise * 0.18f) * envelope;
            });
            _impact = Synthesize("Light impact", 0.18f, (t, random) =>
            {
                var envelope = Mathf.Exp(-11f * t);
                return (Mathf.Sin(t * 380f) * 0.55f + (float)(random.NextDouble() * 2.0 - 1.0) * 0.42f) * envelope;
            });
            _heavyImpact = Synthesize("Heavy impact", 0.42f, (t, random) =>
            {
                var envelope = Mathf.Exp(-7f * t);
                var rumble = Mathf.Sin(t * Mathf.Lerp(220f, 58f, t));
                var noise = (float)(random.NextDouble() * 2.0 - 1.0);
                return (rumble * 0.72f + noise * 0.2f) * envelope;
            });
            _jump = Synthesize("Jump", 0.24f, (t, random) => Mathf.Sin(t * Mathf.Lerp(90f, 520f, t) * 4f) * Mathf.Sin(Mathf.PI * t) * 0.5f);
            _dodge = Synthesize("Dodge", 0.28f, (t, random) =>
                (float)(random.NextDouble() * 2.0 - 1.0) * Mathf.Sin(Mathf.PI * t) * (1f - t) * 0.42f);
            _charge = Synthesize("Skill charge", 0.72f, (t, random) =>
            {
                var frequency = Mathf.Lerp(80f, 680f, t * t);
                return (Mathf.Sin(t * frequency * 6.28f) + Mathf.Sin(t * frequency * 3.17f) * 0.4f) * t * 0.32f;
            });
            _beam = Synthesize("Energy beam", 0.72f, (t, random) =>
            {
                var envelope = Mathf.Sin(Mathf.PI * Mathf.Clamp01(t * 1.35f));
                var noise = (float)(random.NextDouble() * 2.0 - 1.0);
                return (Mathf.Sin(t * 1900f) * 0.34f + Mathf.Sin(t * 410f) * 0.4f + noise * 0.14f) * envelope;
            });
            _warning = Synthesize("Monster warning", 0.5f, (t, random) => Mathf.Sin(t * 150f * 6.28f) * Mathf.Sin(t * Mathf.PI * 4f) * 0.45f);
            _perfectDodge = Synthesize("Perfect dodge", 0.38f, (t, random) =>
            {
                var rise = Mathf.Sin(t * Mathf.Lerp(380f, 1240f, t) * 6.28f);
                return rise * Mathf.Sin(Mathf.PI * t) * 0.48f;
            });
            _pickup = Synthesize("Energy pickup", 0.44f, (t, random) =>
            {
                var step = Mathf.Floor(t * 4f) / 4f;
                return Mathf.Sin(t * Mathf.Lerp(440f, 980f, step) * 6.28f) * Mathf.Exp(-2.2f * t) * 0.42f;
            });
        }

        public void PlayWhoosh(Vector3 position, int combo) => Play(_whoosh, position, 0.68f, 0.9f + combo * 0.08f);
        public void PlayImpact(Vector3 position, int strength) => Play(strength >= 3 ? _heavyImpact : _impact, position, strength >= 3 ? 1f : 0.78f, 0.94f + strength * 0.025f);
        public void PlayJump(Vector3 position) => Play(_jump, position, 0.5f, 1f);
        public void PlayDodge(Vector3 position) => Play(_dodge, position, 0.62f, 1.05f);
        public void PlaySkillCharge(Vector3 position) => Play(_charge, position, 0.82f, 1f);
        public void PlayBeam(Vector3 position) => Play(_beam, position, 1f, 1f);
        public void PlayHeroHit(Vector3 position) => Play(_impact, position, 0.7f, 0.72f);
        public void PlayMonsterWarning(Vector3 position) => Play(_warning, position, 0.72f, 0.78f);
        public void PlayPerfectDodge(Vector3 position) => Play(_perfectDodge, position, 0.9f, 1f);
        public void PlayPickup(Vector3 position) => Play(_pickup, position, 0.78f, 1f);

        private void Play(AudioClip clip, Vector3 position, float volume, float pitch)
        {
            if (clip == null)
            {
                return;
            }

            var sourceObject = new GameObject($"Audio - {clip.name}");
            sourceObject.transform.position = position;
            var source = sourceObject.AddComponent<AudioSource>();
            source.clip = clip;
            source.volume = volume * masterVolume;
            source.pitch = pitch;
            source.spatialBlend = 0.35f;
            source.minDistance = 2f;
            source.maxDistance = 35f;
            source.Play();
            Destroy(sourceObject, clip.length / Mathf.Max(0.1f, pitch) + 0.15f);
        }

        private static AudioClip Synthesize(string clipName, float duration, Func<float, System.Random, float> generator)
        {
            var sampleCount = Mathf.CeilToInt(duration * SampleRate);
            var samples = new float[sampleCount];
            var random = new System.Random(clipName.GetHashCode());
            for (var i = 0; i < sampleCount; i++)
            {
                samples[i] = Mathf.Clamp(generator(i / (float)sampleCount, random), -1f, 1f);
            }

            var clip = AudioClip.Create(clipName, sampleCount, 1, SampleRate, false);
            clip.SetData(samples, 0);
            return clip;
        }
    }
}

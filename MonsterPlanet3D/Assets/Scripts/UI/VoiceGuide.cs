using MonsterPlanet3D.Player;
using UnityEngine;

namespace MonsterPlanet3D.UI
{
    [RequireComponent(typeof(AudioSource))]
    public sealed class VoiceGuide : MonoBehaviour
    {
        [SerializeField] private AudioClip chooseHero;
        [SerializeField] private AudioClip battleStart;
        [SerializeField] private AudioClip energyReady;
        [SerializeField] private AudioClip dodgeWarning;
        [SerializeField] private AudioClip victory;
        [SerializeField] private AudioClip tryAgain;

        private AudioSource _source;
        private HeroController _hero;
        private bool _announcedEnergy;
        private float _nextDodgeHintTime;

        private void Awake()
        {
            _source = GetComponent<AudioSource>();
            _source.playOnAwake = false;
            _source.spatialBlend = 0f;
            _source.volume = 0.92f;
        }

        public void Configure(
            AudioClip choose,
            AudioClip start,
            AudioClip energy,
            AudioClip dodge,
            AudioClip win,
            AudioClip lose)
        {
            chooseHero = choose;
            battleStart = start;
            energyReady = energy;
            dodgeWarning = dodge;
            victory = win;
            tryAgain = lose;
        }

        public void Bind(HeroController hero)
        {
            if (_hero != null) _hero.EnergyChanged -= OnEnergyChanged;
            _hero = hero;
            if (_hero != null) _hero.EnergyChanged += OnEnergyChanged;
        }

        public void PlayChooseHero() => Play(chooseHero);
        public void PlayBattleStart() => Play(battleStart);
        public void PlayResult(bool heroWon) => Play(heroWon ? victory : tryAgain);

        public void PlayDodgeWarning()
        {
            if (Time.unscaledTime < _nextDodgeHintTime)
            {
                return;
            }
            _nextDodgeHintTime = Time.unscaledTime + 8f;
            Play(dodgeWarning);
        }

        private void OnEnergyChanged(float value)
        {
            if (value >= 0.999f && !_announcedEnergy)
            {
                _announcedEnergy = true;
                Play(energyReady);
            }
            else if (value < 0.15f)
            {
                _announcedEnergy = false;
            }
        }

        private void Play(AudioClip clip)
        {
            if (clip == null || _source == null)
            {
                return;
            }
            _source.Stop();
            _source.clip = clip;
            _source.Play();
        }

        private void OnDestroy()
        {
            if (_hero != null) _hero.EnergyChanged -= OnEnergyChanged;
        }
    }
}

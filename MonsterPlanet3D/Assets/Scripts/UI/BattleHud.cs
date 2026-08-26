using System.Collections;
using MonsterPlanet3D.Combat;
using MonsterPlanet3D.Enemy;
using MonsterPlanet3D.Player;
using UnityEngine;
using UnityEngine.UI;

namespace MonsterPlanet3D.UI
{
    public sealed class BattleHud : MonoBehaviour
    {
        [SerializeField] private Slider heroHealth;
        [SerializeField] private Slider monsterHealth;
        [SerializeField] private Slider monsterStagger;
        [SerializeField] private Slider energy;
        [SerializeField] private Text centerMessage;
        [SerializeField] private Text phaseLabel;
        [SerializeField] private Text comboLabel;
        [SerializeField] private Image damageVignette;
        [SerializeField] private GameObject heroSelection;
        [SerializeField] private GameObject battleControls;
        [SerializeField] private GameObject restartButton;
        [SerializeField] private Graphic attackButtonGraphic;
        [SerializeField] private Graphic skillButtonGraphic;

        private HeroController _hero;
        private Combatant _monster;
        private KaijuController _monsterController;
        private Coroutine _messageRoutine;
        private Coroutine _damageRoutine;
        private float _heroHealthTarget = 1f;
        private float _monsterHealthTarget = 1f;
        private float _energyTarget;
        private float _staggerTarget;
        private float _controlsShownAt;

        public void Configure(
            Slider heroHealthSlider,
            Slider monsterHealthSlider,
            Slider monsterStaggerSlider,
            Slider energySlider,
            Text message,
            Text phase,
            Text combo,
            Image damageOverlay,
            GameObject selection,
            GameObject controls,
            GameObject restart,
            Graphic attackGraphic,
            Graphic skillGraphic)
        {
            heroHealth = heroHealthSlider;
            monsterHealth = monsterHealthSlider;
            monsterStagger = monsterStaggerSlider;
            energy = energySlider;
            centerMessage = message;
            phaseLabel = phase;
            comboLabel = combo;
            damageVignette = damageOverlay;
            heroSelection = selection;
            battleControls = controls;
            restartButton = restart;
            attackButtonGraphic = attackGraphic;
            skillButtonGraphic = skillGraphic;
        }

        private void Update()
        {
            var smoothing = 1f - Mathf.Exp(-9f * Time.unscaledDeltaTime);
            if (heroHealth != null) heroHealth.value = Mathf.Lerp(heroHealth.value, _heroHealthTarget, smoothing);
            if (monsterHealth != null) monsterHealth.value = Mathf.Lerp(monsterHealth.value, _monsterHealthTarget, smoothing);
            if (energy != null) energy.value = Mathf.Lerp(energy.value, _energyTarget, smoothing);
            if (monsterStagger != null) monsterStagger.value = Mathf.Lerp(monsterStagger.value, _staggerTarget, smoothing);

            if (skillButtonGraphic == null)
            {
                return;
            }

            if (attackButtonGraphic != null)
            {
                var showAttackHint = battleControls != null && battleControls.activeInHierarchy && Time.unscaledTime - _controlsShownAt < 8f;
                var attackPulse = showAttackHint ? 1f + Mathf.Sin(Time.unscaledTime * 7f) * 0.13f : 1f;
                attackButtonGraphic.rectTransform.localScale = Vector3.one * attackPulse;
            }

            var ready = energy != null && energy.value >= 0.999f;
            var pulse = ready ? 1f + Mathf.Sin(Time.unscaledTime * 8f) * 0.11f : 1f;
            skillButtonGraphic.rectTransform.localScale = Vector3.one * pulse;
            skillButtonGraphic.color = ready
                ? Color.Lerp(new Color(1f, 0.25f, 0.04f, 0.92f), new Color(1f, 0.92f, 0.18f, 1f), Mathf.PingPong(Time.unscaledTime * 2.4f, 1f))
                : new Color(1f, 0.36f, 0.1f, 0.82f);
        }

        public void Bind(HeroController hero, KaijuController monster)
        {
            Unbind();
            _hero = hero;
            _monsterController = monster;
            _monster = monster.Combatant;
            _hero.Combatant.HealthChanged += OnHeroHealthChanged;
            _hero.Combatant.Damaged += OnHeroDamaged;
            _monster.HealthChanged += OnMonsterHealthChanged;
            _hero.EnergyChanged += OnEnergyChanged;
            _hero.ComboChanged += OnComboChanged;
            _hero.PerfectDodge += OnPerfectDodge;
            _monsterController.PhaseChanged += OnPhaseChanged;
            _monsterController.StaggerChanged += OnStaggerChanged;
            _monsterController.ShieldBroken += OnShieldBroken;
            OnHeroHealthChanged(_hero.Combatant.Health, _hero.Combatant.MaxHealth);
            OnMonsterHealthChanged(_monster.Health, _monster.MaxHealth);
            OnEnergyChanged(_hero.Energy01);
            OnStaggerChanged(_monsterController.Stagger01);
            OnPhaseChanged(_monsterController.Phase);
            OnComboChanged(0);
        }

        public void ShowHeroSelection(bool visible)
        {
            if (heroSelection != null) heroSelection.SetActive(visible);
            if (battleControls != null) battleControls.SetActive(!visible);
            if (restartButton != null) restartButton.SetActive(false);
            if (!visible) _controlsShownAt = Time.unscaledTime;
        }

        public void ShowMessage(string message, float seconds = 1.2f)
        {
            if (_messageRoutine != null) StopCoroutine(_messageRoutine);
            _messageRoutine = StartCoroutine(MessageRoutine(message, seconds));
        }

        public void ShowResult(bool heroWon)
        {
            if (_messageRoutine != null) StopCoroutine(_messageRoutine);
            if (centerMessage != null)
            {
                centerMessage.gameObject.SetActive(true);
                centerMessage.text = heroWon ? "守护成功！" : "再试一次，你一定可以！";
                centerMessage.color = heroWon ? new Color(1f, 0.87f, 0.25f) : new Color(0.55f, 0.9f, 1f);
            }
            if (battleControls != null) battleControls.SetActive(false);
            if (restartButton != null) restartButton.SetActive(true);
        }

        private IEnumerator MessageRoutine(string message, float seconds)
        {
            if (centerMessage != null)
            {
                centerMessage.gameObject.SetActive(true);
                centerMessage.text = message;
                centerMessage.color = Color.white;
            }
            yield return new WaitForSeconds(seconds);
            if (centerMessage != null) centerMessage.gameObject.SetActive(false);
            _messageRoutine = null;
        }

        private void OnHeroHealthChanged(float current, float max)
        {
            _heroHealthTarget = max <= 0f ? 0f : current / max;
        }

        private void OnMonsterHealthChanged(float current, float max)
        {
            _monsterHealthTarget = max <= 0f ? 0f : current / max;
        }

        private void OnEnergyChanged(float value)
        {
            _energyTarget = value;
        }

        private void OnStaggerChanged(float value)
        {
            _staggerTarget = value;
        }

        private void OnPhaseChanged(int phase)
        {
            if (phaseLabel != null)
            {
                phaseLabel.text = phase <= 1 ? "第一形态" : (phase == 2 ? "第二形态 · 远程攻击" : "最终形态 · 狂暴");
                phaseLabel.color = phase <= 1
                    ? new Color(0.72f, 0.88f, 1f)
                    : (phase == 2 ? new Color(1f, 0.68f, 0.16f) : new Color(1f, 0.22f, 0.08f));
            }
            if (phase > 1) ShowMessage(phase == 2 ? "怪兽变强了！小心能量弹" : "最终形态！寻找水晶补充能量", 1.8f);
        }

        private void OnComboChanged(int combo)
        {
            if (comboLabel == null)
            {
                return;
            }
            comboLabel.gameObject.SetActive(combo > 1);
            comboLabel.text = combo > 1 ? $"{combo} 连击" : string.Empty;
            comboLabel.transform.localScale = Vector3.one * (combo >= 3 ? 1.22f : 1f);
        }

        private void OnPerfectDodge()
        {
            ShowMessage("完美闪避！能量 +26", 0.9f);
        }

        private void OnShieldBroken()
        {
            ShowMessage("破防！快连续攻击", 1.15f);
        }

        private void OnHeroDamaged(DamageInfo info)
        {
            if (_damageRoutine != null) StopCoroutine(_damageRoutine);
            _damageRoutine = StartCoroutine(DamageFlashRoutine());
        }

        private IEnumerator DamageFlashRoutine()
        {
            if (damageVignette == null)
            {
                yield break;
            }
            var elapsed = 0f;
            const float duration = 0.42f;
            while (elapsed < duration)
            {
                elapsed += Time.unscaledDeltaTime;
                var alpha = Mathf.Sin(Mathf.Clamp01(elapsed / duration) * Mathf.PI) * 0.42f;
                damageVignette.color = new Color(1f, 0.03f, 0.01f, alpha);
                yield return null;
            }
            damageVignette.color = Color.clear;
            _damageRoutine = null;
        }

        private void Unbind()
        {
            if (_hero != null)
            {
                _hero.Combatant.HealthChanged -= OnHeroHealthChanged;
                _hero.Combatant.Damaged -= OnHeroDamaged;
                _hero.EnergyChanged -= OnEnergyChanged;
                _hero.ComboChanged -= OnComboChanged;
                _hero.PerfectDodge -= OnPerfectDodge;
            }
            if (_monster != null) _monster.HealthChanged -= OnMonsterHealthChanged;
            if (_monsterController != null)
            {
                _monsterController.PhaseChanged -= OnPhaseChanged;
                _monsterController.StaggerChanged -= OnStaggerChanged;
                _monsterController.ShieldBroken -= OnShieldBroken;
            }
        }

        private void OnDestroy()
        {
            Unbind();
        }
    }
}

using System;
using System.Collections;
using MonsterPlanet3D.Combat;
using MonsterPlanet3D.Enemy;
using MonsterPlanet3D.Player;
using MonsterPlanet3D.UI;
using UnityEngine;
using UnityEngine.SceneManagement;

namespace MonsterPlanet3D.Core
{
    public sealed class BattleDirector : MonoBehaviour
    {
        [SerializeField] private HeroController hero;
        [SerializeField] private ProceduralHeroVisual heroVisual;
        [SerializeField] private KaijuController monster;
        [SerializeField] private BattleHud hud;
        [SerializeField] private VoiceGuide voiceGuide;
        [SerializeField] private ArenaEncounterDirector arenaEncounter;

        private bool _battleStarted;
        private bool _battleFinished;

        public event Action<bool> BattleFinished;

        public void Configure(
            HeroController player,
            ProceduralHeroVisual playerVisual,
            KaijuController enemy,
            BattleHud battleHud,
            VoiceGuide guide,
            ArenaEncounterDirector encounter)
        {
            hero = player;
            heroVisual = playerVisual;
            monster = enemy;
            hud = battleHud;
            voiceGuide = guide;
            arenaEncounter = encounter;
        }

        private void Start()
        {
            hero.Target = monster.transform;
            hero.SetControlsEnabled(false);
            monster.enabled = false;
            hud.Bind(hero, monster);
            hud.ShowHeroSelection(true);
            voiceGuide?.Bind(hero);
            voiceGuide?.PlayChooseHero();
            hero.Combatant.Died += OnHeroDied;
            monster.Combatant.Died += OnMonsterDied;
        }

        private void Update()
        {
            if (_battleStarted || _battleFinished)
            {
                return;
            }

            if (Input.GetKeyDown(KeyCode.Alpha1)) SelectHero(0);
            if (Input.GetKeyDown(KeyCode.Alpha2)) SelectHero(1);
            if (Input.GetKeyDown(KeyCode.Alpha3)) SelectHero(2);
        }

        public void SelectHero(int index)
        {
            if (_battleStarted || _battleFinished)
            {
                return;
            }

            switch (index)
            {
                case 1:
                    hero.ConfigureStats(8.5f, 11.5f, 92f, 2.7f);
                    heroVisual.ApplyColors(new Color(0.08f, 0.42f, 1f), new Color(0.78f, 0.93f, 1f));
                    break;
                case 2:
                    hero.ConfigureStats(6.7f, 16.5f, 125f, 2.05f);
                    heroVisual.ApplyColors(new Color(1f, 0.2f, 0.08f), new Color(1f, 0.83f, 0.22f));
                    break;
                default:
                    hero.ConfigureStats(7.5f, 13.5f, 105f, 2.35f);
                    heroVisual.ApplyColors(new Color(0.05f, 0.82f, 1f), Color.white);
                    break;
            }

            hero.ConfigureHeroStyle(index);
            heroVisual.SelectExternalModel(index);
            hero.PrepareForBattle();

            hud.ShowHeroSelection(false);
            StartCoroutine(StartBattleRoutine());
        }

        public void SelectHeroFromFlutter(string indexText)
        {
            if (!int.TryParse(indexText, out var index))
            {
                index = 0;
            }
            SelectHero(Mathf.Clamp(index, 0, 2));
        }

        public void RestartBattle()
        {
            Time.timeScale = 1f;
            SceneManager.LoadScene(SceneManager.GetActiveScene().buildIndex);
        }

        private IEnumerator StartBattleRoutine()
        {
            hud.ShowMessage("3", 0.65f);
            yield return new WaitForSeconds(0.7f);
            hud.ShowMessage("2", 0.65f);
            yield return new WaitForSeconds(0.7f);
            hud.ShowMessage("1", 0.65f);
            yield return new WaitForSeconds(0.7f);
            hud.ShowMessage("守护星球！", 1.1f);
            voiceGuide?.PlayBattleStart();
            hero.SetControlsEnabled(true);
            monster.enabled = true;
            arenaEncounter?.BeginEncounter();
            _battleStarted = true;
        }

        private void OnHeroDied(DamageInfo info)
        {
            FinishBattle(false);
        }

        private void OnMonsterDied(DamageInfo info)
        {
            FinishBattle(true);
        }

        private void FinishBattle(bool heroWon)
        {
            if (_battleFinished) return;
            _battleFinished = true;
            hero.SetControlsEnabled(false);
            monster.enabled = false;
            arenaEncounter?.EndEncounter();
            hud.ShowResult(heroWon);
            voiceGuide?.PlayResult(heroWon);
            BattleFinished?.Invoke(heroWon);
        }

        private void OnDestroy()
        {
            if (hero != null) hero.Combatant.Died -= OnHeroDied;
            if (monster != null) monster.Combatant.Died -= OnMonsterDied;
        }
    }
}

using System.Collections;
using MonsterPlanet3D.CameraSystem;
using MonsterPlanet3D.Combat;
using MonsterPlanet3D.Player;
using MonsterPlanet3D.UI;
using MonsterPlanet3D.VFX;
using UnityEngine;
using UnityEngine.Rendering;

namespace MonsterPlanet3D.Core
{
    public sealed class ArenaEncounterDirector : MonoBehaviour
    {
        [SerializeField] private HeroController hero;
        [SerializeField] private BattleHud hud;
        [SerializeField] private BattleVfx vfx;
        [SerializeField] private BattleAudio audioFx;
        [SerializeField] private CombatCamera combatCamera;
        [SerializeField] private Vector3 arenaCenter = new Vector3(0f, 0f, 1f);
        [SerializeField] private float arenaRadius = 7.25f;

        private Coroutine _encounterRoutine;
        private Transform _runtimeEffects;
        private bool _running;

        public void Configure(
            HeroController player,
            BattleHud battleHud,
            BattleVfx battleVfx,
            BattleAudio battleAudio,
            CombatCamera cameraRig)
        {
            hero = player;
            hud = battleHud;
            vfx = battleVfx;
            audioFx = battleAudio;
            combatCamera = cameraRig;
        }

        public void BeginEncounter()
        {
            EndEncounter();
            _running = true;
            _runtimeEffects = new GameObject("Runtime arena events").transform;
            _encounterRoutine = StartCoroutine(EncounterRoutine());
        }

        public void EndEncounter()
        {
            _running = false;
            if (_encounterRoutine != null)
            {
                StopCoroutine(_encounterRoutine);
                _encounterRoutine = null;
            }
            if (_runtimeEffects != null)
            {
                Destroy(_runtimeEffects.gameObject);
                _runtimeEffects = null;
            }
        }

        private IEnumerator EncounterRoutine()
        {
            // Put the first objective in the middle so the player immediately learns
            // that the whole arena is traversable and receives a visible reward.
            yield return new WaitForSeconds(1.2f);
            yield return PowerCrystalSequence(arenaCenter);
            yield return new WaitForSeconds(2.2f);
            var eventIndex = 0;
            while (_running && hero != null && !hero.Combatant.IsDead)
            {
                if (eventIndex % 2 == 0)
                {
                    yield return MeteorSequence(eventIndex >= 4 ? 2 : 1);
                }
                else
                {
                    yield return PowerCrystalSequence(null);
                }
                eventIndex++;
                yield return new WaitForSeconds(Mathf.Max(4.8f, 7.2f - eventIndex * 0.22f));
            }
        }

        private IEnumerator MeteorSequence(int count)
        {
            for (var i = 0; i < count && _running; i++)
            {
                var targetPosition = ChooseArenaPosition(hero.transform.position, 2.1f, 4.8f);
                const float warningDuration = 1.05f;
                vfx?.PlayDangerRing(targetPosition, 1.75f, warningDuration);
                audioFx?.PlayMonsterWarning(targetPosition);

                var meteor = GameObject.CreatePrimitive(PrimitiveType.Sphere);
                meteor.name = "Falling energy meteor";
                meteor.transform.SetParent(_runtimeEffects, true);
                meteor.transform.position = targetPosition + Vector3.up * 11f;
                meteor.transform.localScale = Vector3.one * 0.72f;
                var collider = meteor.GetComponent<Collider>();
                if (collider != null) Destroy(collider);
                var renderer = meteor.GetComponent<Renderer>();
                renderer.sharedMaterial = CreateGlowMaterial(new Color(1f, 0.11f, 0.025f));

                var elapsed = 0f;
                while (elapsed < warningDuration && meteor != null)
                {
                    elapsed += Time.deltaTime;
                    var t = Mathf.Clamp01(elapsed / warningDuration);
                    meteor.transform.position = Vector3.Lerp(
                        targetPosition + Vector3.up * 11f,
                        targetPosition + Vector3.up * 0.22f,
                        t * t);
                    meteor.transform.Rotate(180f * Time.deltaTime, 260f * Time.deltaTime, 90f * Time.deltaTime, Space.Self);
                    yield return null;
                }

                vfx?.PlayMeteorImpact(targetPosition);
                audioFx?.PlayImpact(targetPosition, 4);
                combatCamera?.Shake(0.66f, 0.36f);
                if (hero != null && !hero.Combatant.IsDead)
                {
                    var heroCenter = hero.transform.position + Vector3.up;
                    if (Vector3.Distance(heroCenter, targetPosition + Vector3.up) < 2.05f)
                    {
                        var direction = hero.transform.position - targetPosition;
                        direction.y = 0.28f;
                        hero.Combatant.TryTakeDamage(new DamageInfo(gameObject, 11f, heroCenter, direction, 7.5f, 0.055f));
                    }
                }

                if (meteor != null)
                {
                    var meteorMaterial = renderer != null ? renderer.sharedMaterial : null;
                    Destroy(meteor);
                    if (meteorMaterial != null) Destroy(meteorMaterial);
                }
                yield return new WaitForSeconds(0.34f);
            }
        }

        private IEnumerator PowerCrystalSequence(Vector3? forcedPosition)
        {
            var crystal = GameObject.CreatePrimitive(PrimitiveType.Cube);
            crystal.name = "Collectible light crystal";
            crystal.transform.SetParent(_runtimeEffects, true);
            crystal.transform.position = (forcedPosition ?? ChooseArenaPosition(hero.transform.position, 3f, 6.5f)) + Vector3.up * 0.85f;
            crystal.transform.localScale = new Vector3(0.34f, 0.78f, 0.34f);
            crystal.transform.rotation = Quaternion.Euler(25f, 45f, 25f);
            var collider = crystal.GetComponent<Collider>();
            if (collider != null) Destroy(collider);
            var renderer = crystal.GetComponent<Renderer>();
            renderer.sharedMaterial = CreateGlowMaterial(new Color(0.08f, 0.82f, 1f));
            hud?.ShowMessage("找到光能水晶！", 1.2f);

            var basePosition = crystal.transform.position;
            var elapsed = 0f;
            var collected = false;
            while (_running && crystal != null && elapsed < 10f && hero != null && !hero.Combatant.IsDead)
            {
                elapsed += Time.deltaTime;
                crystal.transform.position = basePosition + Vector3.up * (Mathf.Sin(Time.time * 3.4f) * 0.18f);
                crystal.transform.Rotate(0f, 110f * Time.deltaTime, 0f, Space.World);
                if (Vector3.Distance(hero.transform.position + Vector3.up, crystal.transform.position) < 1.35f)
                {
                    collected = true;
                    hero.CollectPower(32f, 14f);
                    hud?.ShowMessage("能量补充！", 0.8f);
                    break;
                }
                yield return null;
            }

            if (!collected && crystal != null)
            {
                vfx?.PlayShockwave(crystal.transform.position, Vector3.up, 0.8f);
            }
            if (crystal != null)
            {
                var crystalMaterial = renderer != null ? renderer.sharedMaterial : null;
                Destroy(crystal);
                if (crystalMaterial != null) Destroy(crystalMaterial);
            }
        }

        private Vector3 ChooseArenaPosition(Vector3 reference, float minDistance, float maxDistance)
        {
            var direction = Random.insideUnitCircle.normalized;
            if (direction.sqrMagnitude < 0.1f) direction = Vector2.right;
            var distance = Random.Range(minDistance, maxDistance);
            var candidate = reference + new Vector3(direction.x, 0f, direction.y) * distance;
            var fromCenter = candidate - arenaCenter;
            fromCenter.y = 0f;
            if (fromCenter.magnitude > arenaRadius)
            {
                candidate = arenaCenter + fromCenter.normalized * arenaRadius;
            }
            candidate.y = 0f;
            return candidate;
        }

        private static Material CreateGlowMaterial(Color color)
        {
            var shader = GraphicsSettings.currentRenderPipeline != null
                ? Shader.Find("Universal Render Pipeline/Lit") ?? Shader.Find("Standard")
                : Shader.Find("MonsterPlanet/Stylized") ?? Shader.Find("Standard");
            var material = new Material(shader);
            if (material.HasProperty("_BaseColor")) material.SetColor("_BaseColor", color);
            if (material.HasProperty("_Color")) material.SetColor("_Color", color);
            if (material.HasProperty("_EmissionColor"))
            {
                material.EnableKeyword("_EMISSION");
                material.SetColor("_EmissionColor", color * 4f);
            }
            if (material.HasProperty("_Metallic")) material.SetFloat("_Metallic", 0.35f);
            if (material.HasProperty("_Smoothness")) material.SetFloat("_Smoothness", 0.85f);
            return material;
        }

        private void OnDisable()
        {
            EndEncounter();
        }
    }
}

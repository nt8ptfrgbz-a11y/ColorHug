using System;
using System.Collections;
using MonsterPlanet3D.CameraSystem;
using MonsterPlanet3D.Combat;
using MonsterPlanet3D.Core;
using MonsterPlanet3D.VFX;
using MonsterPlanet3D.UI;
using UnityEngine;
using Random = UnityEngine.Random;

namespace MonsterPlanet3D.Enemy
{
    [RequireComponent(typeof(CharacterController), typeof(Combatant))]
    public sealed class KaijuController : MonoBehaviour, IImpulseReceiver
    {
        [SerializeField] private float moveSpeed = 3.6f;
        [SerializeField] private float rotationSpeed = 7f;
        [SerializeField] private float preferredRange = 3.2f;
        [SerializeField] private float attackCooldown = 1.8f;
        [SerializeField] private float attackDamage = 17f;
        [SerializeField] private float staggerThreshold = 58f;
        [SerializeField] private Vector3 arenaCenter = new Vector3(0f, 0f, 1f);
        [SerializeField] private float arenaRadius = 7.7f;
        [SerializeField] private Transform target;
        [SerializeField] private ProceduralKaijuVisual visual;
        [SerializeField] private BattleVfx vfx;
        [SerializeField] private BattleAudio audioFx;
        [SerializeField] private CombatCamera combatCamera;

        private CharacterController _controller;
        private Combatant _combatant;
        private Combatant _targetCombatant;
        private Vector3 _externalVelocity;
        private float _verticalVelocity;
        private float _nextAttackTime;
        private float _strafeDirection = 1f;
        private Coroutine _attackRoutine;
        private float _stagger;
        private float _stunnedUntil;
        private int _phase = 1;
        private GameObject _activeOrb;

        public Combatant Combatant => _combatant;
        public int Phase => _phase;
        public float Stagger01 => Mathf.Clamp01(_stagger / staggerThreshold);
        public bool IsAttacking => _attackRoutine != null;

        public event Action<int> PhaseChanged;
        public event Action<float> StaggerChanged;
        public event Action ShieldBroken;

        private void Awake()
        {
            _controller = GetComponent<CharacterController>();
            _combatant = GetComponent<Combatant>();
        }

        private void OnEnable()
        {
            _combatant.Damaged += OnDamaged;
            _combatant.Died += OnDied;
            _combatant.HealthChanged += OnHealthChanged;
        }

        private void OnDisable()
        {
            _combatant.Damaged -= OnDamaged;
            _combatant.Died -= OnDied;
            _combatant.HealthChanged -= OnHealthChanged;
            if (_activeOrb != null) vfx?.ExplodeEnemyOrb(_activeOrb, false);
        }

        public void Configure(
            Transform hero,
            ProceduralKaijuVisual kaijuVisual,
            BattleVfx battleVfx,
            BattleAudio battleAudio,
            CombatCamera cameraRig,
            float health = 230f)
        {
            if (_controller == null) _controller = GetComponent<CharacterController>();
            if (_combatant == null) _combatant = GetComponent<Combatant>();
            target = hero;
            _targetCombatant = hero != null ? hero.GetComponent<Combatant>() : null;
            visual = kaijuVisual;
            vfx = battleVfx;
            audioFx = battleAudio;
            combatCamera = cameraRig;
            _combatant.Configure(health);
            _phase = 1;
            _stagger = 0f;
            StaggerChanged?.Invoke(0f);
        }

        private void Update()
        {
            if (_combatant.IsDead)
            {
                ApplyGravity(Vector3.zero);
                return;
            }

            if (target == null || _targetCombatant == null || _targetCombatant.IsDead)
            {
                visual?.SetLocomotion(0f);
                ApplyGravity(Vector3.zero);
                return;
            }

            if (Time.time < _stunnedUntil)
            {
                visual?.SetLocomotion(0f);
                ApplyGravity(Vector3.zero);
                return;
            }

            var toTarget = target.position - transform.position;
            toTarget.y = 0f;
            var distance = toTarget.magnitude;
            var direction = distance > 0.01f ? toTarget / distance : transform.forward;
            Face(direction);

            if (_attackRoutine == null && Time.time >= _nextAttackTime && distance <= preferredRange + 0.75f)
            {
                var roll = Random.value;
                _attackRoutine = StartCoroutine(
                    _phase >= 3 && roll < 0.24f
                        ? PlasmaAttackRoutine(2)
                        : (roll < 0.68f ? SwipeAttackRoutine() : StompAttackRoutine()));
                return;
            }

            if (_attackRoutine == null && Time.time >= _nextAttackTime && _phase >= 2 && distance > preferredRange + 1.1f && distance < 11f)
            {
                _attackRoutine = StartCoroutine(PlasmaAttackRoutine(_phase >= 3 ? 2 : 1));
                return;
            }

            var desiredVelocity = Vector3.zero;
            if (_attackRoutine == null)
            {
                if (distance > preferredRange + 0.4f)
                {
                    desiredVelocity = direction * moveSpeed;
                }
                else if (distance < preferredRange - 0.65f)
                {
                    desiredVelocity = -direction * moveSpeed * 0.65f;
                }
                else
                {
                    var strafe = Vector3.Cross(Vector3.up, direction) * _strafeDirection;
                    desiredVelocity = strafe * moveSpeed * 0.42f;
                    if (Random.value < Time.deltaTime * 0.35f) _strafeDirection *= -1f;
                }
            }

            visual?.SetLocomotion(desiredVelocity.magnitude / moveSpeed);
            ApplyGravity(desiredVelocity);
        }

        public void ApplyImpulse(Vector3 direction, float strength)
        {
            _externalVelocity += direction.normalized * strength;
        }

        private void ApplyGravity(Vector3 planarVelocity)
        {
            if (_controller.isGrounded && _verticalVelocity < 0f)
            {
                _verticalVelocity = -2f;
            }
            else
            {
                _verticalVelocity += -25f * Time.deltaTime;
            }

            _externalVelocity = Vector3.MoveTowards(_externalVelocity, Vector3.zero, 7f * Time.deltaTime);
            _controller.Move((planarVelocity + _externalVelocity + Vector3.up * _verticalVelocity) * Time.deltaTime);
            var offset = transform.position - arenaCenter;
            offset.y = 0f;
            if (offset.sqrMagnitude > arenaRadius * arenaRadius)
            {
                _controller.Move(offset.normalized * arenaRadius - offset);
            }
        }

        private void Face(Vector3 direction)
        {
            if (direction.sqrMagnitude < 0.01f)
            {
                return;
            }
            transform.rotation = Quaternion.Slerp(
                transform.rotation,
                Quaternion.LookRotation(direction, Vector3.up),
                1f - Mathf.Exp(-rotationSpeed * Time.deltaTime));
        }

        private IEnumerator SwipeAttackRoutine()
        {
            var warningDuration = _phase >= 3 ? 0.46f : 0.62f;
            visual?.PlayWarning(warningDuration);
            FindFirstObjectByType<VoiceGuide>()?.PlayDodgeWarning();
            vfx?.PlayDangerRing(transform.position + transform.forward * 1.7f, 2.15f, warningDuration);
            audioFx?.PlayMonsterWarning(transform.position);

            var elapsed = 0f;
            while (elapsed < warningDuration)
            {
                elapsed += Time.deltaTime;
                if (target != null)
                {
                    var direction = target.position - transform.position;
                    direction.y = 0f;
                    Face(direction.normalized);
                }
                yield return null;
            }

            visual?.PlaySwipe();
            audioFx?.PlayWhoosh(transform.position, 3);
            yield return new WaitForSeconds(0.16f);

            var center = transform.position + transform.forward * 2f + Vector3.up * 1.1f;
            TryDamageHero(center, 2.2f, attackDamage, 8f);
            vfx?.PlayShockwave(center, transform.forward, 1.9f);
            yield return new WaitForSeconds(0.48f);

            FinishAttack();
        }

        private IEnumerator StompAttackRoutine()
        {
            var warningDuration = _phase >= 3 ? 0.68f : 0.9f;
            visual?.PlayStompCharge(warningDuration);
            FindFirstObjectByType<VoiceGuide>()?.PlayDodgeWarning();
            vfx?.PlayDangerRing(transform.position, 3.65f, warningDuration);
            audioFx?.PlayMonsterWarning(transform.position);
            yield return new WaitForSeconds(warningDuration);

            visual?.PlayStompRelease();
            audioFx?.PlayImpact(transform.position, 4);
            vfx?.PlayShockwave(transform.position + Vector3.up * 0.08f, Vector3.up, 4.4f);
            combatCamera?.Shake(0.65f, 0.38f);
            TryDamageHero(transform.position + Vector3.up, 3.8f, attackDamage * 1.35f, 11f);
            yield return new WaitForSeconds(0.72f);

            FinishAttack();
        }

        private IEnumerator PlasmaAttackRoutine(int shotCount)
        {
            for (var shot = 0; shot < shotCount; shot++)
            {
                var warningDuration = shot == 0 ? 0.72f : 0.36f;
                visual?.PlayWarning(warningDuration);
                vfx?.PlayDangerRing(transform.position + transform.forward * 0.8f, 1.2f, warningDuration);
                audioFx?.PlayMonsterWarning(transform.position);

                var elapsed = 0f;
                while (elapsed < warningDuration)
                {
                    elapsed += Time.deltaTime;
                    if (target != null)
                    {
                        var faceDirection = target.position - transform.position;
                        faceDirection.y = 0f;
                        Face(faceDirection.normalized);
                    }
                    yield return null;
                }

                visual?.PlaySwipe();
                var origin = transform.position + transform.forward * 1.35f + Vector3.up * 2.15f;
                _activeOrb = vfx?.CreateEnemyOrb(origin, _phase >= 3 ? 0.88f : 0.72f);
                if (_activeOrb == null)
                {
                    break;
                }

                var aimPoint = target.position + Vector3.up;
                var direction = (aimPoint - origin).normalized;
                var projectileElapsed = 0f;
                var trailTimer = 0f;
                var hit = false;
                while (projectileElapsed < 1.8f && _activeOrb != null)
                {
                    projectileElapsed += Time.deltaTime;
                    trailTimer -= Time.deltaTime;
                    if (projectileElapsed < 0.32f && target != null)
                    {
                        var desired = ((target.position + Vector3.up) - _activeOrb.transform.position).normalized;
                        direction = Vector3.Slerp(direction, desired, Time.deltaTime * 2.8f).normalized;
                    }

                    _activeOrb.transform.position += direction * (_phase >= 3 ? 11.5f : 9.5f) * Time.deltaTime;
                    _activeOrb.transform.localScale = Vector3.one * (0.72f + Mathf.Sin(Time.time * 22f) * 0.08f);
                    if (trailTimer <= 0f)
                    {
                        trailTimer = 0.075f;
                        vfx?.PlayEnemyOrbTrail(_activeOrb.transform.position, direction);
                    }

                    if (target != null && Vector3.Distance(_activeOrb.transform.position, target.position + Vector3.up) < 1.25f)
                    {
                        hit = TryDamageHero(_activeOrb.transform.position, 1.55f, attackDamage * 0.82f, 7f);
                        break;
                    }

                    var planar = _activeOrb.transform.position - arenaCenter;
                    planar.y = 0f;
                    if (planar.magnitude > arenaRadius + 3f) break;
                    yield return null;
                }

                if (_activeOrb != null)
                {
                    vfx?.ExplodeEnemyOrb(_activeOrb, hit);
                    _activeOrb = null;
                }
                yield return new WaitForSeconds(shotCount > 1 ? 0.22f : 0.4f);
            }

            FinishAttack();
        }

        private bool TryDamageHero(Vector3 center, float radius, float damage, float impulse)
        {
            if (_targetCombatant == null || _targetCombatant.IsDead)
            {
                return false;
            }

            var targetCenter = target.position + Vector3.up;
            if (Vector3.Distance(center, targetCenter) > radius)
            {
                return false;
            }

            var direction = target.position - transform.position;
            direction.y = 0.22f;
            var info = new DamageInfo(gameObject, damage, targetCenter, direction.normalized, impulse, 0.06f);
            if (_targetCombatant.TryTakeDamage(info))
            {
                vfx?.PlayMeleeHit(targetCenter, direction, 3);
                audioFx?.PlayImpact(targetCenter, 3);
                combatCamera?.Shake(0.5f, 0.28f);
                return true;
            }
            return false;
        }

        private void FinishAttack()
        {
            var phaseMultiplier = _phase == 1 ? 1f : (_phase == 2 ? 0.82f : 0.66f);
            _nextAttackTime = Time.time + attackCooldown * phaseMultiplier + Random.Range(-0.12f, 0.28f);
            _attackRoutine = null;
        }

        private void OnDamaged(DamageInfo info)
        {
            visual?.PlayHit();
            if (Time.time < _stunnedUntil)
            {
                return;
            }

            _stagger = Mathf.Min(staggerThreshold, _stagger + info.Amount * (info.Impulse >= 7f ? 1.35f : 1f));
            StaggerChanged?.Invoke(Stagger01);
            if (_stagger < staggerThreshold)
            {
                return;
            }

            _stagger = 0f;
            StaggerChanged?.Invoke(0f);
            if (_attackRoutine != null)
            {
                StopCoroutine(_attackRoutine);
                _attackRoutine = null;
            }
            if (_activeOrb != null)
            {
                vfx?.ExplodeEnemyOrb(_activeOrb, false);
                _activeOrb = null;
            }
            _stunnedUntil = Time.time + 1.45f;
            _nextAttackTime = _stunnedUntil + 0.55f;
            vfx?.PlayShieldBreak(transform.position);
            audioFx?.PlayImpact(transform.position + Vector3.up, 4);
            combatCamera?.Shake(0.72f, 0.4f);
            FindFirstObjectByType<BattleTime>()?.SlowMotion(0.24f, 0.3f);
            ShieldBroken?.Invoke();
        }

        private void OnHealthChanged(float current, float max)
        {
            if (max <= 0f || current <= 0f)
            {
                return;
            }

            var ratio = current / max;
            var nextPhase = ratio <= 0.32f ? 3 : (ratio <= 0.66f ? 2 : 1);
            if (nextPhase == _phase)
            {
                return;
            }

            _phase = nextPhase;
            moveSpeed = _phase == 1 ? 3.6f : (_phase == 2 ? 4.15f : 4.75f);
            visual?.PlayWarning(0.8f);
            vfx?.PlayShieldBreak(transform.position);
            audioFx?.PlayMonsterWarning(transform.position);
            combatCamera?.Shake(0.5f, 0.32f);
            PhaseChanged?.Invoke(_phase);
        }

        private void OnDied(DamageInfo info)
        {
            if (_attackRoutine != null)
            {
                StopCoroutine(_attackRoutine);
                _attackRoutine = null;
            }
            if (_activeOrb != null)
            {
                vfx?.ExplodeEnemyOrb(_activeOrb, false);
                _activeOrb = null;
            }
            visual?.PlayDefeat();
            vfx?.PlayShockwave(transform.position + Vector3.up * 1.2f, Vector3.up, 5f);
            combatCamera?.Shake(0.8f, 0.55f);
        }
    }
}

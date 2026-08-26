using System;
using System.Collections;
using System.Collections.Generic;
using MonsterPlanet3D.CameraSystem;
using MonsterPlanet3D.Combat;
using MonsterPlanet3D.Core;
using MonsterPlanet3D.InputSystem;
using MonsterPlanet3D.VFX;
using UnityEngine;

namespace MonsterPlanet3D.Player
{
    [RequireComponent(typeof(CharacterController), typeof(Combatant))]
    public sealed class HeroController : MonoBehaviour, IImpulseReceiver
    {
        [Header("Locomotion")]
        [SerializeField] private float moveSpeed = 7.2f;
        [SerializeField] private float acceleration = 18f;
        [SerializeField] private float rotationSpeed = 16f;
        [SerializeField] private float jumpHeight = 2.2f;
        [SerializeField] private float gravity = -24f;
        [SerializeField] private Vector3 arenaCenter = new Vector3(0f, 0f, 1f);
        [SerializeField] private float arenaRadius = 8.25f;

        [Header("Combat")]
        [SerializeField] private float baseDamage = 13f;
        [SerializeField] private float attackReach = 2.15f;
        [SerializeField] private float attackRadius = 1.2f;
        [SerializeField] private float attackAssistRange = 11.5f;
        [SerializeField] private float attackLungeSpeed = 17f;
        [SerializeField] private LayerMask damageMask = ~0;
        [SerializeField] private float dodgeSpeed = 15f;
        [SerializeField] private float dodgeDuration = 0.42f;
        [SerializeField] private float perfectDodgeWindow = 0.2f;
        [SerializeField] private float staggerDuration = 0.32f;
        [SerializeField] private float skillDamage = 48f;

        [Header("References")]
        [SerializeField] private Transform attackOrigin;
        [SerializeField] private VirtualJoystick movementJoystick;
        [SerializeField] private ProceduralHeroVisual visual;
        [SerializeField] private BattleVfx vfx;
        [SerializeField] private BattleAudio audioFx;
        [SerializeField] private CombatCamera combatCamera;

        private readonly Collider[] _hitResults = new Collider[16];
        private readonly HashSet<Combatant> _strikeVictims = new HashSet<Combatant>();
        private CharacterController _controller;
        private Combatant _combatant;
        private UnityEngine.Camera _camera;
        private Vector3 _planarVelocity;
        private Vector3 _externalVelocity;
        private Vector3 _lastMoveDirection = Vector3.forward;
        private float _verticalVelocity;
        private Coroutine _attackRoutine;
        private Coroutine _dodgeRoutine;
        private Coroutine _skillRoutine;
        private Coroutine _staggerRoutine;
        private bool _attackBuffered;
        private bool _jumpRequested;
        private bool _controlsEnabled = true;
        private float _energy;
        private float _perfectDodgeUntil;
        private bool _perfectDodgeTriggered;

        public event Action<float> EnergyChanged;
        public event Action<int> ComboChanged;
        public event Action PerfectDodge;

        public Transform Target { get; set; }
        public Combatant Combatant => _combatant;
        public float Energy01 => _energy / 100f;
        public bool IsBusy => _attackRoutine != null || _dodgeRoutine != null || _skillRoutine != null || _staggerRoutine != null;

        private void Awake()
        {
            _controller = GetComponent<CharacterController>();
            _combatant = GetComponent<Combatant>();
            _camera = UnityEngine.Camera.main;
            if (attackOrigin == null)
            {
                attackOrigin = transform;
            }
        }

        private void OnEnable()
        {
            _combatant.Damaged += OnDamaged;
            _combatant.DamageAvoided += OnDamageAvoided;
            _combatant.Died += OnDied;
        }

        private void OnDisable()
        {
            _combatant.Damaged -= OnDamaged;
            _combatant.DamageAvoided -= OnDamageAvoided;
            _combatant.Died -= OnDied;
        }

        private void Update()
        {
            if (!_controlsEnabled || _combatant.IsDead)
            {
                ApplyGravityAndMotion(Vector3.zero, 0f);
                return;
            }

            ReadEditorActions();

            var input = movementJoystick != null ? movementJoystick.Value : ReadKeyboardMovement();
            var desiredDirection = CameraRelativeDirection(input);
            var actionSpeedMultiplier = _attackRoutine != null ? 0.24f : ((_skillRoutine != null || _staggerRoutine != null) ? 0f : 1f);

            if (_dodgeRoutine == null)
            {
                ApplyGravityAndMotion(desiredDirection, actionSpeedMultiplier);
            }

            visual?.SetLocomotion(
                _planarVelocity.magnitude / Mathf.Max(0.1f, moveSpeed),
                _verticalVelocity,
                _controller.isGrounded);

            if (_jumpRequested)
            {
                _jumpRequested = false;
                TryStartJump();
            }
        }

        public void ConfigureStats(float speed, float damage, float maxHealth, float jump)
        {
            moveSpeed = Mathf.Max(1f, speed);
            baseDamage = Mathf.Max(1f, damage);
            jumpHeight = Mathf.Max(0.5f, jump);
            _combatant.Configure(maxHealth);
        }

        public void SetReferences(
            Transform hitOrigin,
            VirtualJoystick joystick,
            ProceduralHeroVisual heroVisual,
            BattleVfx battleVfx,
            BattleAudio battleAudio,
            CombatCamera cameraRig)
        {
            attackOrigin = hitOrigin;
            movementJoystick = joystick;
            visual = heroVisual;
            vfx = battleVfx;
            audioFx = battleAudio;
            combatCamera = cameraRig;
        }

        public void SetControlsEnabled(bool enabled)
        {
            _controlsEnabled = enabled;
        }

        public void CollectPower(float energyAmount, float healthAmount)
        {
            AddEnergy(Mathf.Max(0f, energyAmount));
            _combatant.RestoreHealth(Mathf.Max(0f, healthAmount));
            vfx?.PlayPickup(transform.position + Vector3.up, visual != null ? visual.PrimaryColor : Color.cyan);
            audioFx?.PlayPickup(transform.position);
        }

        public void PrepareForBattle()
        {
            AddEnergy(100f - _energy);
        }

        public void RequestAttack()
        {
            if (!_controlsEnabled || _combatant.IsDead || _dodgeRoutine != null || _skillRoutine != null || _staggerRoutine != null)
            {
                return;
            }

            if (_attackRoutine != null)
            {
                _attackBuffered = true;
                return;
            }

            _attackRoutine = StartCoroutine(ComboRoutine());
        }

        public void RequestDodge()
        {
            if (!_controlsEnabled || _combatant.IsDead || _dodgeRoutine != null || _skillRoutine != null || _staggerRoutine != null)
            {
                return;
            }

            if (_attackRoutine != null)
            {
                StopCoroutine(_attackRoutine);
                _attackRoutine = null;
                _attackBuffered = false;
            }

            _dodgeRoutine = StartCoroutine(DodgeRoutine());
        }

        public void RequestJump()
        {
            if (!_controlsEnabled || IsBusy || _combatant.IsDead)
            {
                return;
            }
            _jumpRequested = true;
        }

        public void RequestSkill()
        {
            if (!_controlsEnabled || _energy < 99.9f || IsBusy || _combatant.IsDead)
            {
                return;
            }

            _skillRoutine = StartCoroutine(SkillRoutine());
        }

        public void ApplyImpulse(Vector3 direction, float strength)
        {
            _externalVelocity += direction.normalized * strength;
        }

        private Vector2 ReadKeyboardMovement()
        {
            var x = 0f;
            var y = 0f;
            if (Input.GetKey(KeyCode.A) || Input.GetKey(KeyCode.LeftArrow)) x -= 1f;
            if (Input.GetKey(KeyCode.D) || Input.GetKey(KeyCode.RightArrow)) x += 1f;
            if (Input.GetKey(KeyCode.S) || Input.GetKey(KeyCode.DownArrow)) y -= 1f;
            if (Input.GetKey(KeyCode.W) || Input.GetKey(KeyCode.UpArrow)) y += 1f;
            return Vector2.ClampMagnitude(new Vector2(x, y), 1f);
        }

        private void ReadEditorActions()
        {
            if (Input.GetKeyDown(KeyCode.J)) RequestAttack();
            if (Input.GetKeyDown(KeyCode.K)) RequestDodge();
            if (Input.GetKeyDown(KeyCode.L)) RequestSkill();
            if (Input.GetKeyDown(KeyCode.Space)) RequestJump();
        }

        private Vector3 CameraRelativeDirection(Vector2 input)
        {
            if (input.sqrMagnitude < 0.0025f)
            {
                return Vector3.zero;
            }

            if (_camera == null)
            {
                _camera = UnityEngine.Camera.main;
            }

            var forward = _camera != null ? _camera.transform.forward : Vector3.forward;
            var right = _camera != null ? _camera.transform.right : Vector3.right;
            forward.y = 0f;
            right.y = 0f;
            return (forward.normalized * input.y + right.normalized * input.x).normalized;
        }

        private void ApplyGravityAndMotion(Vector3 desiredDirection, float speedMultiplier)
        {
            var targetVelocity = desiredDirection * moveSpeed * speedMultiplier;
            _planarVelocity = Vector3.MoveTowards(
                _planarVelocity,
                targetVelocity,
                acceleration * Time.deltaTime);

            if (desiredDirection.sqrMagnitude > 0.01f)
            {
                _lastMoveDirection = desiredDirection;
                if (_attackRoutine == null && _skillRoutine == null)
                {
                    var desiredRotation = Quaternion.LookRotation(desiredDirection, Vector3.up);
                    transform.rotation = Quaternion.Slerp(
                        transform.rotation,
                        desiredRotation,
                        1f - Mathf.Exp(-rotationSpeed * Time.deltaTime));
                }
            }
            else if ((_attackRoutine != null || _skillRoutine != null) && Target != null)
            {
                FaceTarget(18f);
            }

            if (_controller.isGrounded && _verticalVelocity < 0f)
            {
                _verticalVelocity = -2f;
            }
            else
            {
                _verticalVelocity += gravity * Time.deltaTime;
            }

            _externalVelocity = Vector3.MoveTowards(_externalVelocity, Vector3.zero, 12f * Time.deltaTime);
            var motion = _planarVelocity + _externalVelocity + Vector3.up * _verticalVelocity;
            _controller.Move(motion * Time.deltaTime);
            KeepInsideArena();
        }

        private void KeepInsideArena()
        {
            var offset = transform.position - arenaCenter;
            offset.y = 0f;
            if (offset.sqrMagnitude <= arenaRadius * arenaRadius)
            {
                return;
            }
            var correction = offset.normalized * arenaRadius - offset;
            _controller.Move(correction);
        }

        private void TryStartJump()
        {
            if (!_controller.isGrounded || _dodgeRoutine != null || _skillRoutine != null)
            {
                return;
            }

            _verticalVelocity = Mathf.Sqrt(jumpHeight * -2f * gravity);
            visual?.PlayJump();
            audioFx?.PlayJump(transform.position);
            vfx?.PlayJumpBurst(transform.position);
        }

        private IEnumerator ComboRoutine()
        {
            var comboIndex = 1;
            do
            {
                _attackBuffered = false;
                ComboChanged?.Invoke(comboIndex);
                FaceTarget(22f);
                visual?.PlayAttack(comboIndex);
                audioFx?.PlayWhoosh(transform.position, comboIndex);

                var windup = comboIndex == 3 ? 0.22f : 0.13f;
                var windupElapsed = 0f;
                while (windupElapsed < windup)
                {
                    windupElapsed += Time.deltaTime;
                    FaceTarget(30f);
                    ApplyAttackAssist(comboIndex, windupElapsed / windup);
                    yield return null;
                }

                if (comboIndex == 3)
                {
                    vfx?.PlayCharge(attackOrigin.position, transform.forward);
                }

                var damageMultiplier = comboIndex == 1 ? 1f : (comboIndex == 2 ? 1.15f : 1.7f);
                var impulse = comboIndex == 3 ? 7.5f : 2.5f;
                PerformMeleeStrike(baseDamage * damageMultiplier, impulse, comboIndex);

                var recovery = comboIndex == 3 ? 0.46f : 0.30f;
                var elapsed = 0f;
                while (elapsed < recovery)
                {
                    elapsed += Time.deltaTime;
                    if (_attackBuffered && elapsed > recovery * 0.28f)
                    {
                        break;
                    }
                    yield return null;
                }

                if (!_attackBuffered || comboIndex >= 3)
                {
                    break;
                }

                comboIndex++;
            }
            while (comboIndex <= 3);

            ComboChanged?.Invoke(0);
            _attackRoutine = null;
            _attackBuffered = false;
        }

        private void ApplyAttackAssist(int comboIndex, float normalizedTime)
        {
            if (Target == null || !_controller.enabled)
            {
                return;
            }

            var toTarget = Target.position - transform.position;
            toTarget.y = 0f;
            var distance = toTarget.magnitude;
            if (distance <= 1.65f || distance > attackAssistRange)
            {
                return;
            }

            var ease = Mathf.Sin(Mathf.Clamp01(normalizedTime) * Mathf.PI);
            var speed = attackLungeSpeed * ease * (comboIndex == 3 ? 1.22f : 1f);
            var maxStep = Mathf.Max(0f, distance - 1.55f);
            _controller.Move(toTarget.normalized * Mathf.Min(speed * Time.deltaTime, maxStep));
        }

        private void PerformMeleeStrike(float damage, float impulse, int comboIndex)
        {
            _strikeVictims.Clear();
            var center = attackOrigin.position + transform.forward * attackReach;
            var count = Physics.OverlapSphereNonAlloc(
                center,
                attackRadius + (comboIndex == 3 ? 0.5f : 0f),
                _hitResults,
                damageMask,
                QueryTriggerInteraction.Ignore);

            var hitSomething = false;
            for (var i = 0; i < count; i++)
            {
                var targetCombatant = _hitResults[i].GetComponentInParent<Combatant>();
                if (targetCombatant == null || targetCombatant == _combatant || !_strikeVictims.Add(targetCombatant))
                {
                    continue;
                }

                var hitPoint = _hitResults[i].ClosestPoint(center);
                var info = new DamageInfo(gameObject, damage, hitPoint, transform.forward, impulse, comboIndex == 3 ? 0.075f : 0.04f);
                if (!targetCombatant.TryTakeDamage(info))
                {
                    continue;
                }

                hitSomething = true;
                AddEnergy(comboIndex == 3 ? 22f : 12f);
                vfx?.PlayMeleeHit(hitPoint, transform.forward, comboIndex);
                audioFx?.PlayImpact(hitPoint, comboIndex);
                combatCamera?.Shake(comboIndex == 3 ? 0.42f : 0.22f, comboIndex == 3 ? 0.22f : 0.12f);
                FindFirstObjectByType<BattleTime>()?.HitStop(info.HitStop);
            }

            if (!hitSomething && comboIndex == 3)
            {
                vfx?.PlayShockwave(center, transform.forward, 1.6f);
            }

            if (!hitSomething)
            {
                PerformLightShot(damage, impulse, comboIndex);
            }
        }

        private void PerformLightShot(float damage, float impulse, int comboIndex)
        {
            if (Target == null)
            {
                return;
            }

            var targetCombatant = Target.GetComponent<Combatant>() ?? Target.GetComponentInParent<Combatant>();
            if (targetCombatant == null || targetCombatant == _combatant || targetCombatant.IsDead)
            {
                return;
            }

            var origin = attackOrigin.position + Vector3.up * 0.18f;
            var targetPoint = Target.position + Vector3.up * 1.35f;
            var toTarget = targetPoint - origin;
            var distance = toTarget.magnitude;
            if (distance < attackReach || distance > 14f)
            {
                return;
            }

            var direction = toTarget / Mathf.Max(0.01f, distance);
            var rangedDamage = damage * (comboIndex == 3 ? 0.88f : 0.68f);
            var info = new DamageInfo(gameObject, rangedDamage, targetPoint, direction, impulse * 0.35f, comboIndex == 3 ? 0.055f : 0.025f);
            if (!targetCombatant.TryTakeDamage(info))
            {
                return;
            }

            AddEnergy(comboIndex == 3 ? 18f : 9f);
            vfx?.PlayPulseShot(origin, direction, distance, visual != null ? visual.PrimaryColor : Color.cyan, comboIndex == 3);
            audioFx?.PlayWhoosh(origin, comboIndex);
            audioFx?.PlayImpact(targetPoint, comboIndex);
            combatCamera?.Shake(comboIndex == 3 ? 0.3f : 0.14f, comboIndex == 3 ? 0.17f : 0.08f);
            FindFirstObjectByType<BattleTime>()?.HitStop(info.HitStop);
        }

        private IEnumerator DodgeRoutine()
        {
            var input = movementJoystick != null ? movementJoystick.Value : ReadKeyboardMovement();
            var dodgeDirection = CameraRelativeDirection(input);
            if (dodgeDirection.sqrMagnitude < 0.01f)
            {
                if (Target != null)
                {
                    dodgeDirection = transform.position - Target.position;
                    dodgeDirection.y = 0f;
                }
                if (dodgeDirection.sqrMagnitude < 0.01f)
                {
                    dodgeDirection = _lastMoveDirection.sqrMagnitude > 0.01f ? _lastMoveDirection : -transform.forward;
                }
            }

            dodgeDirection.Normalize();
            transform.rotation = Quaternion.LookRotation(dodgeDirection, Vector3.up);
            _combatant.GrantInvulnerability(dodgeDuration * 0.88f);
            _perfectDodgeUntil = Time.time + perfectDodgeWindow;
            _perfectDodgeTriggered = false;
            visual?.PlayDodge(dodgeDuration);
            audioFx?.PlayDodge(transform.position);

            var elapsed = 0f;
            var afterimageTimer = 0f;
            while (elapsed < dodgeDuration)
            {
                elapsed += Time.deltaTime;
                afterimageTimer -= Time.deltaTime;
                var t = Mathf.Clamp01(elapsed / dodgeDuration);
                var speed = dodgeSpeed * Mathf.Sin(Mathf.Lerp(0.35f, Mathf.PI, t));
                _controller.Move((dodgeDirection * speed + Vector3.down * 2f) * Time.deltaTime);

                if (afterimageTimer <= 0f)
                {
                    afterimageTimer = 0.07f;
                    vfx?.PlayAfterimage(transform.position + Vector3.up, transform.rotation, visual != null ? visual.PrimaryColor : Color.cyan);
                }
                yield return null;
            }

            _dodgeRoutine = null;
            _perfectDodgeUntil = 0f;
        }

        private IEnumerator SkillRoutine()
        {
            AddEnergy(-100f);
            FaceTarget(30f);
            visual?.PlaySkill(1.45f);
            audioFx?.PlaySkillCharge(transform.position);
            combatCamera?.BeginHeroMoment(0.38f);

            var chargePoint = attackOrigin.position + transform.forward * 0.7f;
            vfx?.PlaySkillCharge(chargePoint, visual != null ? visual.PrimaryColor : Color.cyan);
            yield return new WaitForSeconds(0.62f);

            FaceTarget(40f);
            var origin = attackOrigin.position + Vector3.up * 0.2f;
            var direction = Target != null
                ? ((Target.position + Vector3.up) - origin).normalized
                : transform.forward;

            audioFx?.PlayBeam(origin);
            vfx?.PlayBeam(origin, direction, 18f, 0.55f, visual != null ? visual.PrimaryColor : Color.cyan);
            combatCamera?.Shake(0.65f, 0.42f);

            var hits = Physics.SphereCastAll(origin, 0.72f, direction, 18f, damageMask, QueryTriggerInteraction.Ignore);
            _strikeVictims.Clear();
            foreach (var hit in hits)
            {
                var targetCombatant = hit.collider.GetComponentInParent<Combatant>();
                if (targetCombatant == null || targetCombatant == _combatant || !_strikeVictims.Add(targetCombatant))
                {
                    continue;
                }

                var info = new DamageInfo(gameObject, skillDamage, hit.point, direction, 12f, 0.11f);
                if (targetCombatant.TryTakeDamage(info))
                {
                    vfx?.PlayShockwave(hit.point, direction, 2.6f);
                    audioFx?.PlayImpact(hit.point, 4);
                    FindFirstObjectByType<BattleTime>()?.HitStop(info.HitStop);
                }
            }

            yield return new WaitForSeconds(0.62f);
            _skillRoutine = null;
        }

        private void FaceTarget(float speed)
        {
            if (Target == null)
            {
                return;
            }

            var direction = Target.position - transform.position;
            direction.y = 0f;
            if (direction.sqrMagnitude < 0.01f)
            {
                return;
            }

            transform.rotation = Quaternion.Slerp(
                transform.rotation,
                Quaternion.LookRotation(direction.normalized, Vector3.up),
                1f - Mathf.Exp(-speed * Time.deltaTime));
        }

        private void AddEnergy(float amount)
        {
            _energy = Mathf.Clamp(_energy + amount, 0f, 100f);
            EnergyChanged?.Invoke(Energy01);
        }

        private void OnDamaged(DamageInfo info)
        {
            CancelOffense();
            _combatant.GrantInvulnerability(staggerDuration + 0.12f);
            if (_staggerRoutine != null) StopCoroutine(_staggerRoutine);
            _staggerRoutine = StartCoroutine(StaggerRoutine());
            visual?.PlayHit();
            audioFx?.PlayHeroHit(transform.position);
            combatCamera?.Shake(0.3f, 0.16f);
        }

        private void OnDamageAvoided(DamageInfo info)
        {
            if (_dodgeRoutine == null || _perfectDodgeTriggered || Time.time > _perfectDodgeUntil)
            {
                return;
            }

            _perfectDodgeTriggered = true;
            AddEnergy(26f);
            vfx?.PlayPerfectDodge(transform.position, visual != null ? visual.PrimaryColor : Color.cyan);
            audioFx?.PlayPerfectDodge(transform.position);
            combatCamera?.Shake(0.24f, 0.16f);
            FindFirstObjectByType<BattleTime>()?.SlowMotion(0.28f, 0.24f);
            PerfectDodge?.Invoke();
        }

        private IEnumerator StaggerRoutine()
        {
            var elapsed = 0f;
            while (elapsed < staggerDuration)
            {
                elapsed += Time.deltaTime;
                yield return null;
            }
            _staggerRoutine = null;
        }

        private void CancelOffense()
        {
            if (_attackRoutine != null)
            {
                StopCoroutine(_attackRoutine);
                _attackRoutine = null;
            }
            if (_skillRoutine != null)
            {
                StopCoroutine(_skillRoutine);
                _skillRoutine = null;
            }
            _attackBuffered = false;
            ComboChanged?.Invoke(0);
        }

        private void OnDied(DamageInfo info)
        {
            _controlsEnabled = false;
            visual?.PlayDefeat();
        }
    }
}

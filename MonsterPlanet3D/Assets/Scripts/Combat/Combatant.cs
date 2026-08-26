using System;
using UnityEngine;

namespace MonsterPlanet3D.Combat
{
    [DisallowMultipleComponent]
    public sealed class Combatant : MonoBehaviour
    {
        [SerializeField, Min(1f)] private float maxHealth = 100f;
        [SerializeField] private bool invulnerable;

        private float _health;
        private float _temporaryInvulnerabilityUntil;

        public event Action<float, float> HealthChanged;
        public event Action<DamageInfo> Damaged;
        public event Action<DamageInfo> DamageAvoided;
        public event Action<DamageInfo> Died;

        public float Health => _health;
        public float MaxHealth => maxHealth;
        public float Health01 => maxHealth <= 0f ? 0f : _health / maxHealth;
        public bool IsDead { get; private set; }
        public bool IsInvulnerable => invulnerable || Time.time < _temporaryInvulnerabilityUntil;

        private void Awake()
        {
            _health = maxHealth;
        }

        public void Configure(float health)
        {
            maxHealth = Mathf.Max(1f, health);
            ResetCombatant();
        }

        public void ResetCombatant()
        {
            IsDead = false;
            _health = maxHealth;
            _temporaryInvulnerabilityUntil = 0f;
            HealthChanged?.Invoke(_health, maxHealth);
        }

        public void GrantInvulnerability(float seconds)
        {
            _temporaryInvulnerabilityUntil = Mathf.Max(
                _temporaryInvulnerabilityUntil,
                Time.time + Mathf.Max(0f, seconds));
        }

        public void RestoreHealth(float amount)
        {
            if (IsDead || amount <= 0f)
            {
                return;
            }

            _health = Mathf.Min(maxHealth, _health + amount);
            HealthChanged?.Invoke(_health, maxHealth);
        }

        public bool TryTakeDamage(DamageInfo info)
        {
            if (IsDead || info.Amount <= 0f)
            {
                return false;
            }

            if (IsInvulnerable)
            {
                DamageAvoided?.Invoke(info);
                return false;
            }

            _health = Mathf.Max(0f, _health - info.Amount);
            HealthChanged?.Invoke(_health, maxHealth);
            Damaged?.Invoke(info);

            if (info.Impulse > 0f && TryGetComponent<IImpulseReceiver>(out var receiver))
            {
                receiver.ApplyImpulse(info.Direction, info.Impulse);
            }

            if (_health <= 0f)
            {
                IsDead = true;
                Died?.Invoke(info);
            }

            return true;
        }
    }
}

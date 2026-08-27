using UnityEngine;
using MonsterPlanet3D.Player;

namespace MonsterPlanet3D.Core
{
    public sealed class ExternalAnimationDriver : MonoBehaviour
    {
        [SerializeField] private Animator animator;
        [SerializeField] private string idleState = "Idle";
        [SerializeField] private string moveState = "Run";
        [SerializeField] private string jumpState = "Jump";
        [SerializeField] private string attackState = "Punch";
        [SerializeField] private string skillState = "Weapon";
        [SerializeField] private string hitState = "HitReact";
        [SerializeField] private string deathState = "Death";
        [SerializeField] private GuardianPoseAnimator guardianPose;

        private string _currentState;
        private float _actionLockedUntil;
        private float _speed;
        private bool _grounded = true;
        private bool _defeated;

        public void Configure(
            Animator targetAnimator,
            string idle,
            string move,
            string jump,
            string attack,
            string skill,
            string hit,
            string death)
        {
            animator = targetAnimator;
            idleState = idle;
            moveState = move;
            jumpState = jump;
            attackState = attack;
            skillState = skill;
            hitState = hit;
            deathState = death;
            guardianPose = GetComponent<GuardianPoseAnimator>();
        }

        public void SetLocomotion(float speed, bool grounded)
        {
            _speed = speed;
            _grounded = grounded;
            guardianPose?.SetLocomotion(speed, grounded);
        }

        public void PlayJump()
        {
            guardianPose?.PlayJump(0.55f);
            PlayAction(jumpState, 0.55f, 0.06f);
        }

        public void PlayAttack(int combo)
        {
            var duration = combo == 3 ? 0.72f : 0.46f;
            guardianPose?.PlayAttack(combo, duration);
            PlayAction(attackState, duration, 0.045f);
        }

        public void PlayDodge(float duration)
        {
            guardianPose?.PlayDodge(duration);
            PlayAction(moveState, duration, 0.03f, 1.65f);
        }

        public void PlaySkill(float duration)
        {
            guardianPose?.PlaySkill(duration);
            PlayAction(skillState, duration, 0.06f);
        }

        public void PlayHit()
        {
            guardianPose?.PlayHit(0.32f);
            PlayAction(hitState, 0.32f, 0.025f);
        }

        public void PlayDefeat()
        {
            _defeated = true;
            guardianPose?.PlayDefeat();
            PlayState(deathState, 0.12f, 1f);
        }

        private void Update()
        {
            if (_defeated || animator == null || Time.time < _actionLockedUntil)
            {
                return;
            }

            if (!_grounded)
            {
                PlayState(jumpState, 0.12f, 1f);
            }
            else
            {
                PlayState(_speed > 0.1f ? moveState : idleState, 0.15f, Mathf.Lerp(0.85f, 1.28f, _speed));
            }
        }

        private void PlayAction(string stateName, float lockDuration, float fade, float speed = 1f)
        {
            _actionLockedUntil = Time.time + lockDuration;
            PlayState(stateName, fade, speed, true);
        }

        private void PlayState(string stateName, float fade, float speed, bool force = false)
        {
            if (animator == null || string.IsNullOrEmpty(stateName) || (!force && _currentState == stateName))
            {
                return;
            }

            var shortHash = Animator.StringToHash(stateName);
            if (!animator.HasState(0, shortHash))
            {
                var fullHash = Animator.StringToHash("Base Layer." + stateName);
                if (!animator.HasState(0, fullHash))
                {
                    return;
                }
            }

            animator.speed = speed;
            animator.CrossFadeInFixedTime(stateName, fade, 0, 0f);
            _currentState = stateName;
        }
    }
}

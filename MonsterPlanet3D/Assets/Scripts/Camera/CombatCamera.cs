using System.Collections;
using UnityEngine;

namespace MonsterPlanet3D.CameraSystem
{
    [RequireComponent(typeof(UnityEngine.Camera))]
    public sealed class CombatCamera : MonoBehaviour
    {
        [SerializeField] private Transform follow;
        [SerializeField] private Transform target;
        [SerializeField] private float distance = 7.45f;
        [SerializeField] private float height = 3.85f;
        [SerializeField] private float shoulderOffset = 0.92f;
        [SerializeField] private float followSmoothTime = 0.12f;
        [SerializeField] private float rotationSharpness = 8f;
        [SerializeField] private LayerMask collisionMask = 0;

        private UnityEngine.Camera _camera;
        private float _shakeAmplitude;
        private float _shakeRemaining;
        private float _shakeDuration;
        private float _defaultFov;
        private float _momentFovOffset;
        private Coroutine _heroMomentRoutine;
        private readonly RaycastHit[] _collisionHits = new RaycastHit[12];

        public void Configure(Transform followTarget, Transform combatTarget)
        {
            follow = followTarget;
            target = combatTarget;
        }

        private void Awake()
        {
            _camera = GetComponent<UnityEngine.Camera>();
            _defaultFov = _camera.fieldOfView;
        }

        private void LateUpdate()
        {
            if (follow == null)
            {
                return;
            }

            var focus = follow.position + Vector3.up * 1.45f;
            var combatDirection = target != null ? target.position - follow.position : follow.forward * 5f;
            var combatDistance = target != null ? combatDirection.magnitude : 8f;
            combatDirection.y = 0f;
            if (combatDirection.sqrMagnitude < 0.01f)
            {
                combatDirection = follow.forward;
            }
            combatDirection.Normalize();

            var right = Vector3.Cross(Vector3.up, combatDirection).normalized;
            var framing = Mathf.InverseLerp(3f, 13f, combatDistance);
            var dynamicDistance = distance + Mathf.Lerp(-1.15f, 0.82f, framing);
            var dynamicHeight = height + Mathf.Lerp(-0.38f, 0.36f, framing);
            var desiredPosition = focus - combatDirection * dynamicDistance + Vector3.up * dynamicHeight + right * shoulderOffset;
            var rayDirection = desiredPosition - focus;
            var hitCount = collisionMask.value == 0
                ? 0
                : Physics.SphereCastNonAlloc(
                    focus,
                    0.28f,
                    rayDirection.normalized,
                    _collisionHits,
                    rayDirection.magnitude,
                    collisionMask,
                    QueryTriggerInteraction.Ignore);
            var nearestDistance = float.MaxValue;
            for (var i = 0; i < hitCount; i++)
            {
                var hitTransform = _collisionHits[i].collider.transform;
                if (hitTransform.IsChildOf(follow) || (target != null && hitTransform.IsChildOf(target)))
                {
                    continue;
                }
                if (_collisionHits[i].distance < nearestDistance)
                {
                    nearestDistance = _collisionHits[i].distance;
                    desiredPosition = _collisionHits[i].point - rayDirection.normalized * 0.3f;
                }
            }

            var followSharpness = 1f / Mathf.Max(0.04f, followSmoothTime);
            var position = Vector3.Lerp(
                transform.position,
                desiredPosition,
                1f - Mathf.Exp(-followSharpness * Time.unscaledDeltaTime));
            if (_shakeRemaining > 0f)
            {
                _shakeRemaining -= Time.unscaledDeltaTime;
                var fade = Mathf.Clamp01(_shakeRemaining / Mathf.Max(0.01f, _shakeDuration));
                var noise = new Vector3(
                    Mathf.PerlinNoise(Time.unscaledTime * 31f, 0f) - 0.5f,
                    Mathf.PerlinNoise(0f, Time.unscaledTime * 37f) - 0.5f,
                    Mathf.PerlinNoise(Time.unscaledTime * 23f, 9f) - 0.5f);
                position += noise * (_shakeAmplitude * fade * 2f);
            }
            else
            {
                _shakeAmplitude = 0f;
                _shakeDuration = 0f;
            }

            transform.position = position;
            var lookPoint = focus;
            if (target != null)
            {
                var distanceToTarget = Vector3.Distance(follow.position, target.position);
                var targetWeight = Mathf.InverseLerp(18f, 5f, distanceToTarget) * 0.28f;
                lookPoint = Vector3.Lerp(focus, target.position + Vector3.up, targetWeight);
            }

            var lookRotation = Quaternion.LookRotation(lookPoint - transform.position, Vector3.up);
            transform.rotation = Quaternion.Slerp(
                transform.rotation,
                lookRotation,
                1f - Mathf.Exp(-rotationSharpness * Time.unscaledDeltaTime));

            var distanceFov = Mathf.Lerp(-3f, 4f, framing);
            var targetFov = _defaultFov + distanceFov + _momentFovOffset;
            _camera.fieldOfView = Mathf.Lerp(
                _camera.fieldOfView,
                targetFov,
                1f - Mathf.Exp(-8f * Time.unscaledDeltaTime));

        }

        public void Shake(float amplitude, float duration)
        {
            _shakeAmplitude = Mathf.Max(_shakeAmplitude, amplitude);
            _shakeRemaining = Mathf.Max(_shakeRemaining, duration);
            _shakeDuration = Mathf.Max(_shakeDuration, duration);
        }

        public void BeginHeroMoment(float duration)
        {
            if (_heroMomentRoutine != null)
            {
                StopCoroutine(_heroMomentRoutine);
            }
            _heroMomentRoutine = StartCoroutine(HeroMomentRoutine(duration));
        }

        private IEnumerator HeroMomentRoutine(float duration)
        {
            var elapsed = 0f;
            while (elapsed < duration)
            {
                elapsed += Time.unscaledDeltaTime;
                var t = Mathf.Clamp01(elapsed / Mathf.Max(0.01f, duration));
                _momentFovOffset = -10f * Mathf.Sin(t * Mathf.PI);
                yield return null;
            }
            _momentFovOffset = 0f;
            _heroMomentRoutine = null;
        }
    }
}

using System.Text;
using UnityEngine;

namespace MonsterPlanet3D.Player
{
    /// <summary>
    /// Adds reliable, child-friendly action poses on top of imported animation.
    /// World-space bone aiming avoids FBX/glTF axis differences and guarantees
    /// the visible guardian never falls back to a T pose.
    /// </summary>
    [DefaultExecutionOrder(180)]
    public sealed class GuardianPoseAnimator : MonoBehaviour
    {
        private enum ActionPose
        {
            None,
            Attack,
            Dodge,
            Skill,
            Hit,
            Defeat
        }

        [SerializeField] private Transform modelRoot;
        [SerializeField] private Transform pelvis;
        [SerializeField] private Transform lowerSpine;
        [SerializeField] private Transform chest;
        [SerializeField] private Transform head;
        [SerializeField] private Transform leftUpperArm;
        [SerializeField] private Transform leftForearm;
        [SerializeField] private Transform leftHand;
        [SerializeField] private Transform rightUpperArm;
        [SerializeField] private Transform rightForearm;
        [SerializeField] private Transform rightHand;
        [SerializeField] private Transform leftThigh;
        [SerializeField] private Transform leftCalf;
        [SerializeField] private Transform leftFoot;
        [SerializeField] private Transform rightThigh;
        [SerializeField] private Transform rightCalf;
        [SerializeField] private Transform rightFoot;

        private float _locomotion;
        private bool _grounded = true;
        private ActionPose _action;
        private float _actionStart;
        private float _actionDuration;
        private int _combo;
        private float _smoothedLocomotion;
        private Vector3 _modelBaseLocalPosition;

        public void Configure(Transform visibleModel)
        {
            modelRoot = visibleModel;
            pelvis = Find("pelvis");
            lowerSpine = Find("spine01");
            chest = Find("spine03");
            head = Find("head");
            leftUpperArm = Find("upperarml");
            leftForearm = Find("lowerarml");
            leftHand = Find("handl");
            rightUpperArm = Find("upperarmr");
            rightForearm = Find("lowerarmr");
            rightHand = Find("handr");
            leftThigh = Find("thighl");
            leftCalf = Find("calfl");
            leftFoot = Find("footl");
            rightThigh = Find("thighr");
            rightCalf = Find("calfr");
            rightFoot = Find("footr");
            CacheBasePose();
        }

        private void Awake() => CacheBasePose();

        private void CacheBasePose()
        {
            if (modelRoot != null)
            {
                _modelBaseLocalPosition = modelRoot.localPosition;
            }
        }

        public void SetLocomotion(float speed, bool grounded)
        {
            _locomotion = Mathf.Clamp01(speed);
            _grounded = grounded;
        }

        public void PlayJump(float duration) => Begin(ActionPose.None, duration, 0);
        public void PlayAttack(int combo, float duration) => Begin(ActionPose.Attack, duration, combo);
        public void PlayDodge(float duration) => Begin(ActionPose.Dodge, duration, 0);
        public void PlaySkill(float duration) => Begin(ActionPose.Skill, duration, 0);
        public void PlayHit(float duration) => Begin(ActionPose.Hit, duration, 0);
        public void PlayDefeat() => Begin(ActionPose.Defeat, 99f, 0);

        private void Begin(ActionPose pose, float duration, int combo)
        {
            _action = pose;
            _actionStart = Time.time;
            _actionDuration = Mathf.Max(0.01f, duration);
            _combo = combo;
        }

        private void LateUpdate()
        {
            if (modelRoot == null || leftUpperArm == null || rightUpperArm == null)
            {
                return;
            }

            var up = modelRoot.root.up;
            var forward = modelRoot.root.forward;
            var right = modelRoot.root.right;
            var actionT = Mathf.Clamp01((Time.time - _actionStart) / Mathf.Max(0.01f, _actionDuration));
            if (_action != ActionPose.None && _action != ActionPose.Defeat && actionT >= 1f)
            {
                _action = ActionPose.None;
            }

            _smoothedLocomotion = Mathf.MoveTowards(_smoothedLocomotion, _locomotion, Time.deltaTime * 4.8f);
            var gait = _grounded ? _smoothedLocomotion : 0f;
            var cycle = Time.time * Mathf.Lerp(4.8f, 10.8f, gait);
            var cycleSin = Mathf.Sin(cycle);
            var cycleCos = Mathf.Cos(cycle);
            var swing = cycleSin * gait;
            var leftStride = -swing;
            var rightStride = swing;
            var leftLift = Mathf.Max(0f, leftStride) * gait;
            var rightLift = Mathf.Max(0f, rightStride) * gait;

            // Bent elbows and phase-shifted lower arms stop the run from
            // looking like straight wooden rods swinging from the shoulder.
            var leftArmDirection = (-up * 0.84f - right * 0.16f + forward * swing * 0.54f).normalized;
            var rightArmDirection = (-up * 0.84f + right * 0.16f - forward * swing * 0.54f).normalized;
            var leftForearmDirection = (-up * 0.68f + right * 0.12f + forward * (0.22f + swing * 0.24f)).normalized;
            var rightForearmDirection = (-up * 0.68f - right * 0.12f + forward * (0.22f - swing * 0.24f)).normalized;
            var leftLegDirection = (-up * 0.94f + forward * leftStride * 0.43f - right * 0.035f).normalized;
            var rightLegDirection = (-up * 0.94f + forward * rightStride * 0.43f + right * 0.035f).normalized;
            var leftCalfDirection = (-up * 0.86f - forward * leftLift * 0.52f + forward * Mathf.Max(0f, -leftStride) * 0.08f).normalized;
            var rightCalfDirection = (-up * 0.86f - forward * rightLift * 0.52f + forward * Mathf.Max(0f, -rightStride) * 0.08f).normalized;
            var hipYaw = swing * 7.5f;
            var hipRoll = cycleCos * gait * 2.2f;
            var torsoYaw = -swing * 10f;
            var torsoLean = -gait * 5f;
            var bodyBob = Mathf.Abs(cycleSin) * gait * 0.032f;

            if (!_grounded)
            {
                leftArmDirection = (up * 0.32f - right * 0.45f + forward * 0.22f).normalized;
                rightArmDirection = (up * 0.32f + right * 0.45f + forward * 0.22f).normalized;
                leftForearmDirection = (up * 0.15f - right * 0.3f + forward * 0.52f).normalized;
                rightForearmDirection = (up * 0.15f + right * 0.3f + forward * 0.52f).normalized;
                leftLegDirection = (-up * 0.68f + forward * 0.58f - right * 0.12f).normalized;
                rightLegDirection = (-up * 0.68f - forward * 0.58f + right * 0.12f).normalized;
                leftCalfDirection = (-up * 0.52f - forward * 0.65f).normalized;
                rightCalfDirection = (-up * 0.82f + forward * 0.22f).normalized;
                torsoLean = -12f;
                bodyBob = 0.045f;
            }

            switch (_action)
            {
                case ActionPose.Attack:
                {
                    var punch = Mathf.Sin(actionT * Mathf.PI);
                    var useLeft = _combo == 2;
                    if (_combo >= 3)
                    {
                        leftArmDirection = (forward * 0.8f - right * 0.45f + up * 0.08f).normalized;
                        rightArmDirection = (forward * 0.8f + right * 0.45f + up * 0.08f).normalized;
                        leftForearmDirection = forward;
                        rightForearmDirection = forward;
                        torsoLean = -14f * punch;
                    }
                    else if (useLeft)
                    {
                        leftArmDirection = (forward * 0.92f - right * 0.22f + up * 0.12f * punch).normalized;
                        leftForearmDirection = forward;
                        rightArmDirection = (-up * 0.72f + right * 0.28f - forward * 0.28f).normalized;
                        torsoYaw = -24f * punch;
                    }
                    else
                    {
                        rightArmDirection = (forward * 0.92f + right * 0.22f + up * 0.12f * punch).normalized;
                        rightForearmDirection = forward;
                        leftArmDirection = (-up * 0.72f - right * 0.28f - forward * 0.28f).normalized;
                        torsoYaw = 24f * punch;
                    }
                    hipYaw = -torsoYaw * 0.42f;
                    break;
                }
                case ActionPose.Dodge:
                    leftArmDirection = (-up * 0.38f - right * 0.25f - forward * 0.72f).normalized;
                    rightArmDirection = (-up * 0.38f + right * 0.25f - forward * 0.72f).normalized;
                    leftForearmDirection = (-up * 0.2f - forward * 0.9f).normalized;
                    rightForearmDirection = (-up * 0.2f - forward * 0.9f).normalized;
                    torsoLean = -23f;
                    hipRoll = 13f * Mathf.Sin(actionT * Mathf.PI * 2f);
                    break;
                case ActionPose.Skill:
                    leftArmDirection = (forward * 0.55f + right * 0.72f + up * 0.2f).normalized;
                    rightArmDirection = (forward * 0.78f - right * 0.48f + up * 0.12f).normalized;
                    leftForearmDirection = (forward * 0.88f - right * 0.36f).normalized;
                    rightForearmDirection = forward;
                    torsoYaw = -18f * Mathf.Sin(actionT * Mathf.PI);
                    torsoLean = -9f;
                    break;
                case ActionPose.Hit:
                    leftArmDirection = (up * 0.12f - right * 0.62f - forward * 0.5f).normalized;
                    rightArmDirection = (up * 0.12f + right * 0.62f - forward * 0.5f).normalized;
                    torsoLean = 18f * Mathf.Sin(actionT * Mathf.PI);
                    break;
                case ActionPose.Defeat:
                    leftArmDirection = (-up * 0.35f - right * 0.72f).normalized;
                    rightArmDirection = (-up * 0.35f + right * 0.72f).normalized;
                    leftLegDirection = (-up * 0.5f - right * 0.38f).normalized;
                    rightLegDirection = (-up * 0.5f + right * 0.38f).normalized;
                    torsoLean = 62f;
                    hipRoll = -18f;
                    break;
            }

            modelRoot.localPosition = _modelBaseLocalPosition + Vector3.up * bodyBob;
            ApplyBodyMotion(up, right, hipYaw, hipRoll, torsoYaw, torsoLean);

            var blend = 1f - Mathf.Exp(-14f * Time.deltaTime);
            Aim(leftUpperArm, leftForearm, leftArmDirection, blend);
            Aim(rightUpperArm, rightForearm, rightArmDirection, blend);
            Aim(leftForearm, leftHand, leftForearmDirection, blend);
            Aim(rightForearm, rightHand, rightForearmDirection, blend);
            Aim(leftThigh, leftCalf, leftLegDirection, blend);
            Aim(rightThigh, rightCalf, rightLegDirection, blend);
            Aim(leftCalf, leftFoot, leftCalfDirection, blend);
            Aim(rightCalf, rightFoot, rightCalfDirection, blend);
        }

        private void ApplyBodyMotion(
            Vector3 up,
            Vector3 right,
            float hipYaw,
            float hipRoll,
            float torsoYaw,
            float torsoLean)
        {
            if (pelvis != null)
            {
                pelvis.rotation = Quaternion.AngleAxis(hipYaw, up)
                    * Quaternion.AngleAxis(hipRoll, modelRoot.root.forward)
                    * pelvis.rotation;
            }
            if (lowerSpine != null)
            {
                lowerSpine.rotation = Quaternion.AngleAxis(torsoYaw * 0.42f, up)
                    * Quaternion.AngleAxis(torsoLean * 0.45f, right)
                    * lowerSpine.rotation;
            }
            if (chest != null)
            {
                chest.rotation = Quaternion.AngleAxis(torsoYaw * 0.58f, up)
                    * Quaternion.AngleAxis(torsoLean * 0.55f, right)
                    * chest.rotation;
            }
            if (head != null)
            {
                head.rotation = Quaternion.AngleAxis(-torsoYaw * 0.22f, up)
                    * Quaternion.AngleAxis(-torsoLean * 0.16f, right)
                    * head.rotation;
            }
        }

        private static void Aim(Transform from, Transform to, Vector3 desiredDirection, float blend)
        {
            if (from == null || to == null)
            {
                return;
            }

            var currentDirection = to.position - from.position;
            if (currentDirection.sqrMagnitude < 0.0001f)
            {
                return;
            }

            var desired = Quaternion.FromToRotation(currentDirection.normalized, desiredDirection.normalized) * from.rotation;
            from.rotation = Quaternion.Slerp(from.rotation, desired, blend);
        }

        private Transform Find(string normalizedName)
        {
            foreach (var child in modelRoot.GetComponentsInChildren<Transform>(true))
            {
                if (Normalize(child.name) == normalizedName)
                {
                    return child;
                }
            }
            return null;
        }

        private static string Normalize(string value)
        {
            var builder = new StringBuilder(value.Length);
            foreach (var character in value.ToLowerInvariant())
            {
                if (char.IsLetterOrDigit(character)) builder.Append(character);
            }
            return builder.ToString();
        }
    }
}

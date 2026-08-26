using MonsterPlanet3D.Core;
using UnityEngine;

namespace MonsterPlanet3D.Enemy
{
    public sealed class ProceduralKaijuVisual : MonoBehaviour
    {
        private enum Pose
        {
            None,
            Warning,
            Swipe,
            StompCharge,
            StompRelease,
            Hit,
            Defeat
        }

        [SerializeField] private Transform body;
        [SerializeField] private Transform head;
        [SerializeField] private Transform leftArm;
        [SerializeField] private Transform rightArm;
        [SerializeField] private Transform leftLeg;
        [SerializeField] private Transform rightLeg;
        [SerializeField] private Transform tail;
        [SerializeField] private ExternalAnimationDriver externalModel;

        private Pose _pose;
        private float _poseStart;
        private float _poseDuration = 0.4f;
        private float _locomotion;
        private Vector3 _bodyBasePosition;

        public void Configure(
            Transform bodyTransform,
            Transform headTransform,
            Transform leftArmTransform,
            Transform rightArmTransform,
            Transform leftLegTransform,
            Transform rightLegTransform,
            Transform tailTransform)
        {
            body = bodyTransform;
            head = headTransform;
            leftArm = leftArmTransform;
            rightArm = rightArmTransform;
            leftLeg = leftLegTransform;
            rightLeg = rightLegTransform;
            tail = tailTransform;
            _bodyBasePosition = body != null ? body.localPosition : Vector3.zero;
        }

        private void Awake()
        {
            if (body != null) _bodyBasePosition = body.localPosition;
        }

        public void SetLocomotion(float speed) => _locomotion = Mathf.Clamp01(speed);
        public void ConfigureExternalModel(ExternalAnimationDriver model)
        {
            externalModel = model;
            if (externalModel != null && body != null) body.gameObject.SetActive(false);
        }

        public void PlayWarning(float duration) => SetPose(Pose.Warning, duration);
        public void PlaySwipe()
        {
            SetPose(Pose.Swipe, 0.64f);
            externalModel?.PlayAttack(1);
        }

        public void PlayStompCharge(float duration) => SetPose(Pose.StompCharge, duration);
        public void PlayStompRelease()
        {
            SetPose(Pose.StompRelease, 0.72f);
            externalModel?.PlayAttack(3);
        }

        public void PlayHit()
        {
            SetPose(Pose.Hit, 0.3f);
            externalModel?.PlayHit();
        }

        public void PlayDefeat()
        {
            SetPose(Pose.Defeat, 99f);
            externalModel?.PlayDefeat();
        }

        private void SetPose(Pose pose, float duration)
        {
            _pose = pose;
            _poseStart = Time.time;
            _poseDuration = Mathf.Max(0.01f, duration);
        }

        private void LateUpdate()
        {
            externalModel?.SetLocomotion(_locomotion, true);
            if (body == null || leftArm == null || rightArm == null || leftLeg == null || rightLeg == null)
            {
                return;
            }

            var t = Mathf.Clamp01((Time.time - _poseStart) / _poseDuration);
            if (_pose != Pose.None && _pose != Pose.Defeat && t >= 1f)
            {
                _pose = Pose.None;
            }

            var cycle = Time.time * Mathf.Lerp(3f, 7f, _locomotion);
            var stride = Mathf.Sin(cycle) * 28f * _locomotion;
            var bodyRot = Vector3.zero;
            var leftArmRot = new Vector3(-stride * 0.65f, 0f, -18f);
            var rightArmRot = new Vector3(stride * 0.65f, 0f, 18f);
            var leftLegRot = new Vector3(stride, 0f, 0f);
            var rightLegRot = new Vector3(-stride, 0f, 0f);
            var motion = Mathf.Sin(t * Mathf.PI);

            switch (_pose)
            {
                case Pose.Warning:
                    bodyRot.x = Mathf.Sin(t * Mathf.PI * 8f) * 4f;
                    leftArmRot = new Vector3(-55f, 0f, -42f);
                    rightArmRot = new Vector3(-55f, 0f, 42f);
                    break;
                case Pose.Swipe:
                    bodyRot.y = Mathf.Lerp(-55f, 78f, Mathf.SmoothStep(0f, 1f, t));
                    rightArmRot = new Vector3(-15f, 0f, Mathf.Lerp(105f, -115f, t));
                    break;
                case Pose.StompCharge:
                    bodyRot.x = -22f * Mathf.SmoothStep(0f, 1f, t);
                    rightLegRot.x = -65f * Mathf.SmoothStep(0f, 1f, t);
                    leftArmRot.z = -55f;
                    rightArmRot.z = 55f;
                    break;
                case Pose.StompRelease:
                    bodyRot.x = 28f * motion;
                    rightLegRot.x = Mathf.Lerp(-65f, 48f, Mathf.SmoothStep(0f, 1f, t));
                    break;
                case Pose.Hit:
                    bodyRot = new Vector3(-15f * motion, 0f, -25f * motion);
                    break;
                case Pose.Defeat:
                    bodyRot.z = Mathf.Lerp(0f, -86f, Mathf.SmoothStep(0f, 1f, t));
                    leftArmRot.z = -65f;
                    rightArmRot.z = 65f;
                    break;
            }

            body.localPosition = _bodyBasePosition + Vector3.up * Mathf.Abs(Mathf.Sin(cycle)) * 0.08f * _locomotion;
            body.localRotation = Quaternion.Euler(bodyRot);
            leftArm.localRotation = Quaternion.Euler(leftArmRot);
            rightArm.localRotation = Quaternion.Euler(rightArmRot);
            leftLeg.localRotation = Quaternion.Euler(leftLegRot);
            rightLeg.localRotation = Quaternion.Euler(rightLegRot);
            if (head != null) head.localRotation = Quaternion.Euler(0f, Mathf.Sin(Time.time * 1.7f) * 5f, 0f);
            if (tail != null) tail.localRotation = Quaternion.Euler(0f, Mathf.Sin(Time.time * 2.2f) * 24f, 0f);
        }
    }
}

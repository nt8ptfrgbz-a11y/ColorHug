using UnityEngine;

namespace MonsterPlanet3D.Player
{
    [DefaultExecutionOrder(200)]
    public sealed class BoneAccessoryFollower : MonoBehaviour
    {
        [SerializeField] private Transform targetBone;
        [SerializeField] private Vector3 positionOffset;
        [SerializeField] private Vector3 rotationOffset;
        [SerializeField] private Vector3 fixedScale = Vector3.one;

        private Renderer _renderer;

        public void Configure(Transform bone, Vector3 localPositionOffset, Vector3 localRotationOffset, Vector3 scale)
        {
            targetBone = bone;
            positionOffset = localPositionOffset;
            rotationOffset = localRotationOffset;
            fixedScale = scale;
            _renderer = GetComponent<Renderer>();
            SnapToBone();
        }

        private void LateUpdate()
        {
            SnapToBone();
        }

        private void SnapToBone()
        {
            if (targetBone == null)
            {
                return;
            }

            if (_renderer == null) _renderer = GetComponent<Renderer>();
            var targetIsVisible = targetBone.gameObject.activeInHierarchy;
            if (_renderer != null) _renderer.enabled = targetIsVisible;
            if (!targetIsVisible)
            {
                return;
            }

            // Imported animation bones can carry extreme non-uniform scale. Following
            // only position and rotation keeps helmets and energy cores rigid.
            transform.SetPositionAndRotation(
                targetBone.position + targetBone.rotation * positionOffset,
                targetBone.rotation * Quaternion.Euler(rotationOffset));
            transform.localScale = fixedScale;
        }
    }
}

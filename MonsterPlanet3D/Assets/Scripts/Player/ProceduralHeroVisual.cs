using MonsterPlanet3D.Core;
using UnityEngine;

namespace MonsterPlanet3D.Player
{
    public sealed class ProceduralHeroVisual : MonoBehaviour
    {
        private enum ActionPose
        {
            None,
            Attack1,
            Attack2,
            Attack3,
            Dodge,
            Skill,
            Hit,
            Defeat
        }

        [SerializeField] private Transform body;
        [SerializeField] private Transform head;
        [SerializeField] private Transform leftArm;
        [SerializeField] private Transform rightArm;
        [SerializeField] private Transform leftLeg;
        [SerializeField] private Transform rightLeg;
        [SerializeField] private Renderer[] renderers;
        [SerializeField] private ExternalAnimationDriver[] externalModels;
        [SerializeField] private Color primaryColor = new Color(0.05f, 0.75f, 1f);
        [SerializeField] private Color accentColor = Color.white;

        private ActionPose _action;
        private float _actionStarted;
        private float _actionDuration;
        private float _locomotion;
        private float _verticalVelocity;
        private bool _grounded = true;
        private Vector3 _bodyBasePosition;
        private ExternalAnimationDriver _activeExternalModel;
        private int _selectedExternalModel;
        private MaterialPropertyBlock _materialProperties;

        private static readonly int BaseColorId = Shader.PropertyToID("_BaseColor");
        private static readonly int LegacyColorId = Shader.PropertyToID("_Color");
        private static readonly int EmissionColorId = Shader.PropertyToID("_EmissionColor");
        private static readonly int RimColorId = Shader.PropertyToID("_RimColor");

        public Color PrimaryColor => primaryColor;

        public void Configure(
            Transform bodyTransform,
            Transform headTransform,
            Transform leftArmTransform,
            Transform rightArmTransform,
            Transform leftLegTransform,
            Transform rightLegTransform,
            Renderer[] suitRenderers,
            Color primary,
            Color accent)
        {
            body = bodyTransform;
            head = headTransform;
            leftArm = leftArmTransform;
            rightArm = rightArmTransform;
            leftLeg = leftLegTransform;
            rightLeg = rightLegTransform;
            renderers = suitRenderers;
            primaryColor = primary;
            accentColor = accent;
            CacheBasePose();
            ApplyColors(primary, accent);
        }

        private void Awake()
        {
            CacheBasePose();
        }

        private void CacheBasePose()
        {
            _bodyBasePosition = body != null ? body.localPosition : Vector3.zero;
        }

        public void ApplyColors(Color primary, Color accent)
        {
            primaryColor = primary;
            accentColor = accent;
            if (renderers == null)
            {
                return;
            }

            for (var i = 0; i < renderers.Length; i++)
            {
                var targetRenderer = renderers[i];
                if (targetRenderer == null)
                {
                    continue;
                }

                var color = i % 3 == 0 ? primary : (i % 3 == 1 ? accent : Color.Lerp(primary, Color.black, 0.25f));
                _materialProperties ??= new MaterialPropertyBlock();
                targetRenderer.GetPropertyBlock(_materialProperties);
                var sharedMaterial = targetRenderer.sharedMaterial;
                if (sharedMaterial != null && sharedMaterial.HasProperty(BaseColorId))
                {
                    _materialProperties.SetColor(BaseColorId, color);
                }
                else
                {
                    _materialProperties.SetColor(LegacyColorId, color);
                }

                if (sharedMaterial != null && sharedMaterial.HasProperty(EmissionColorId))
                {
                    _materialProperties.SetColor(EmissionColorId, i % 3 == 0 ? primary * 1.5f : Color.black);
                }

                targetRenderer.SetPropertyBlock(_materialProperties);
                _materialProperties.Clear();
            }

            ApplyExternalSkin();
        }

        public void ConfigureExternalModels(ExternalAnimationDriver[] models)
        {
            externalModels = models;
            if (externalModels == null || externalModels.Length == 0)
            {
                return;
            }

            if (body != null) body.gameObject.SetActive(false);
            SelectExternalModel(0);
        }

        public void SelectExternalModel(int index)
        {
            if (externalModels == null || externalModels.Length == 0)
            {
                return;
            }

            index = Mathf.Clamp(index, 0, externalModels.Length - 1);
            _selectedExternalModel = index;
            for (var i = 0; i < externalModels.Length; i++)
            {
                if (externalModels[i] != null) externalModels[i].gameObject.SetActive(i == index);
            }
            _activeExternalModel = externalModels[index];
            ApplyExternalSkin();
        }

        private void ApplyExternalSkin()
        {
            if (_activeExternalModel == null)
            {
                return;
            }

            var renderersToTint = _activeExternalModel.GetComponentsInChildren<Renderer>(true);
            for (var rendererIndex = 0; rendererIndex < renderersToTint.Length; rendererIndex++)
            {
                var targetRenderer = renderersToTint[rendererIndex];
                var materials = targetRenderer.sharedMaterials;
                for (var materialIndex = 0; materialIndex < materials.Length; materialIndex++)
                {
                    var material = materials[materialIndex];
                    if (material == null)
                    {
                        continue;
                    }

                    var alternating = (rendererIndex + materialIndex) % 3;
                    var tint = alternating == 0
                        ? Color.Lerp(accentColor, primaryColor, 0.42f)
                        : (alternating == 1
                            ? Color.Lerp(Color.white, accentColor, 0.56f)
                            : Color.Lerp(primaryColor, Color.white, 0.28f));
                    if (_selectedExternalModel == 1)
                    {
                        tint = Color.Lerp(tint, new Color(0.18f, 0.34f, 1f), 0.24f);
                    }
                    else if (_selectedExternalModel == 2)
                    {
                        tint = Color.Lerp(tint, new Color(1f, 0.18f, 0.035f), 0.18f);
                    }

                    var rendererName = targetRenderer.gameObject.name;
                    var isLightPart = rendererName.StartsWith("Light ");
                    var isGlowPart = rendererName.Contains("Eye") || rendererName.Contains("Core");
                    if (rendererName.Contains("Helmet"))
                    {
                        tint = Color.Lerp(Color.white, accentColor, 0.18f);
                    }
                    else if (isLightPart)
                    {
                        tint = isGlowPart ? Color.Lerp(primaryColor, Color.white, 0.42f) : primaryColor;
                    }

                    _materialProperties ??= new MaterialPropertyBlock();
                    targetRenderer.GetPropertyBlock(_materialProperties, materialIndex);
                    if (material.HasProperty(BaseColorId)) _materialProperties.SetColor(BaseColorId, tint);
                    if (material.HasProperty(LegacyColorId)) _materialProperties.SetColor(LegacyColorId, tint);
                    if (material.HasProperty(RimColorId)) _materialProperties.SetColor(RimColorId, Color.Lerp(primaryColor, Color.white, 0.32f));
                    if (material.HasProperty(EmissionColorId)) _materialProperties.SetColor(EmissionColorId, isGlowPart ? primaryColor * 4.2f : primaryColor * 0.28f);
                    targetRenderer.SetPropertyBlock(_materialProperties, materialIndex);
                    _materialProperties.Clear();
                }
            }
        }

        public void SetLocomotion(float normalizedSpeed, float verticalVelocity, bool grounded)
        {
            _locomotion = Mathf.Clamp01(normalizedSpeed);
            _verticalVelocity = verticalVelocity;
            _grounded = grounded;
            _activeExternalModel?.SetLocomotion(_locomotion, grounded);
        }

        public void PlayJump()
        {
            _activeExternalModel?.PlayJump();
        }

        public void PlayAttack(int comboIndex)
        {
            var pose = comboIndex == 1 ? ActionPose.Attack1 : (comboIndex == 2 ? ActionPose.Attack2 : ActionPose.Attack3);
            SetAction(pose, comboIndex == 3 ? 0.82f : 0.52f);
            _activeExternalModel?.PlayAttack(comboIndex);
        }

        public void PlayDodge(float duration)
        {
            SetAction(ActionPose.Dodge, duration);
            _activeExternalModel?.PlayDodge(duration);
        }

        public void PlaySkill(float duration)
        {
            SetAction(ActionPose.Skill, duration);
            _activeExternalModel?.PlaySkill(duration);
        }

        public void PlayHit()
        {
            SetAction(ActionPose.Hit, 0.34f);
            _activeExternalModel?.PlayHit();
        }

        public void PlayDefeat()
        {
            SetAction(ActionPose.Defeat, 99f);
            _activeExternalModel?.PlayDefeat();
        }

        private void SetAction(ActionPose pose, float duration)
        {
            _action = pose;
            _actionStarted = Time.time;
            _actionDuration = Mathf.Max(0.01f, duration);
        }

        private void LateUpdate()
        {
            if (body == null || leftArm == null || rightArm == null || leftLeg == null || rightLeg == null)
            {
                return;
            }

            var actionT = Mathf.Clamp01((Time.time - _actionStarted) / _actionDuration);
            if (_action != ActionPose.None && actionT >= 1f && _action != ActionPose.Defeat)
            {
                _action = ActionPose.None;
            }

            var runCycle = Time.time * Mathf.Lerp(6f, 12f, _locomotion);
            var stride = Mathf.Sin(runCycle) * 42f * _locomotion;
            var bob = Mathf.Abs(Mathf.Sin(runCycle)) * 0.07f * _locomotion;
            var bodyEuler = Vector3.zero;
            var leftArmEuler = new Vector3(-stride, 0f, -6f);
            var rightArmEuler = new Vector3(stride, 0f, 6f);
            var leftLegEuler = new Vector3(stride, 0f, 0f);
            var rightLegEuler = new Vector3(-stride, 0f, 0f);

            if (!_grounded)
            {
                var rising = Mathf.Clamp(_verticalVelocity * 0.08f, -1f, 1f);
                leftArmEuler = new Vector3(-55f - rising * 18f, 0f, -18f);
                rightArmEuler = new Vector3(-55f - rising * 18f, 0f, 18f);
                leftLegEuler = new Vector3(28f, 0f, -8f);
                rightLegEuler = new Vector3(-18f, 0f, 8f);
                bodyEuler.x = -8f * rising;
            }

            ApplyActionPose(actionT, ref bodyEuler, ref leftArmEuler, ref rightArmEuler, ref leftLegEuler, ref rightLegEuler);

            body.localPosition = _bodyBasePosition + Vector3.up * bob;
            body.localRotation = Quaternion.Euler(bodyEuler);
            leftArm.localRotation = Quaternion.Euler(leftArmEuler);
            rightArm.localRotation = Quaternion.Euler(rightArmEuler);
            leftLeg.localRotation = Quaternion.Euler(leftLegEuler);
            rightLeg.localRotation = Quaternion.Euler(rightLegEuler);
            if (head != null && _action == ActionPose.None)
            {
                head.localRotation = Quaternion.Euler(0f, Mathf.Sin(Time.time * 1.4f) * 3f, 0f);
            }
        }

        private void ApplyActionPose(
            float t,
            ref Vector3 bodyEuler,
            ref Vector3 leftArmEuler,
            ref Vector3 rightArmEuler,
            ref Vector3 leftLegEuler,
            ref Vector3 rightLegEuler)
        {
            var punch = Mathf.Sin(t * Mathf.PI);
            switch (_action)
            {
                case ActionPose.Attack1:
                    bodyEuler.y = punch * 28f;
                    rightArmEuler = new Vector3(Mathf.Lerp(-45f, -105f, punch), 0f, -80f * punch);
                    leftArmEuler = new Vector3(-20f, 0f, -35f);
                    break;
                case ActionPose.Attack2:
                    bodyEuler.y = -punch * 38f;
                    leftArmEuler = new Vector3(Mathf.Lerp(-45f, -110f, punch), 0f, 82f * punch);
                    rightArmEuler = new Vector3(-25f, 0f, 35f);
                    rightLegEuler.x = -34f * punch;
                    break;
                case ActionPose.Attack3:
                    var charge = Mathf.SmoothStep(0f, 1f, Mathf.Clamp01(t / 0.42f));
                    var release = Mathf.SmoothStep(0f, 1f, Mathf.Clamp01((t - 0.42f) / 0.24f));
                    bodyEuler.x = 18f * charge - 32f * release;
                    leftArmEuler = new Vector3(-140f * charge + 90f * release, 0f, -42f + 42f * release);
                    rightArmEuler = new Vector3(-140f * charge + 90f * release, 0f, 42f - 42f * release);
                    break;
                case ActionPose.Dodge:
                    bodyEuler = new Vector3(22f, 0f, -18f);
                    leftArmEuler = new Vector3(38f, 0f, -48f);
                    rightArmEuler = new Vector3(38f, 0f, 48f);
                    leftLegEuler.x = -48f;
                    rightLegEuler.x = 35f;
                    break;
                case ActionPose.Skill:
                    var skillCharge = Mathf.Clamp01(t / 0.42f);
                    var fire = Mathf.Clamp01((t - 0.42f) / 0.18f);
                    bodyEuler.x = -10f * fire;
                    leftArmEuler = new Vector3(-70f * skillCharge, 0f, -85f + 70f * fire);
                    rightArmEuler = new Vector3(-70f * skillCharge, 0f, 85f - 70f * fire);
                    break;
                case ActionPose.Hit:
                    bodyEuler = new Vector3(-18f * punch, 0f, 22f * punch);
                    leftArmEuler.z -= 32f * punch;
                    rightArmEuler.z += 32f * punch;
                    break;
                case ActionPose.Defeat:
                    bodyEuler = new Vector3(0f, 0f, Mathf.Lerp(0f, 82f, Mathf.SmoothStep(0f, 1f, t)));
                    leftArmEuler = new Vector3(0f, 0f, -45f);
                    rightArmEuler = new Vector3(0f, 0f, 45f);
                    break;
            }
        }
    }
}

using System.Collections;
using UnityEngine;
using UnityEngine.Rendering;

namespace MonsterPlanet3D.VFX
{
    public sealed class BattleVfx : MonoBehaviour
    {
        private Material _particleMaterial;
        private Material _additiveMaterial;

        private void Awake()
        {
            _particleMaterial = CreateMaterial(false);
            _additiveMaterial = CreateMaterial(true);
        }

        public void PlayJumpBurst(Vector3 position)
        {
            EmitBurst(position + Vector3.up * 0.08f, Color.white, 18, 0.55f, 3.8f, 0.15f, 0.36f, Vector3.up);
        }

        public void PlayCharge(Vector3 position, Vector3 forward)
        {
            EmitBurst(position, new Color(0.25f, 0.9f, 1f), 22, 0.45f, 2.2f, 0.06f, 0.22f, -forward);
        }

        public void PlayMeleeHit(Vector3 position, Vector3 direction, int combo)
        {
            var color = combo == 3 ? new Color(1f, 0.78f, 0.12f) : new Color(0.25f, 0.92f, 1f);
            EmitBurst(position, color, combo == 3 ? 46 : 28, 0.42f, combo == 3 ? 8f : 5.5f, 0.08f, combo == 3 ? 0.38f : 0.25f, direction);
            StartCoroutine(SlashArcRoutine(position, direction, color, combo == 3 ? 2.15f : 1.35f));
            if (combo == 3)
            {
                PlayShockwave(position, direction, 2.2f);
            }
        }

        public void PlayShockwave(Vector3 position, Vector3 forward, float radius)
        {
            StartCoroutine(ShockwaveRoutine(position, forward, radius));
        }

        public void PlayAfterimage(Vector3 position, Quaternion rotation, Color color)
        {
            var ghost = GameObject.CreatePrimitive(PrimitiveType.Capsule);
            ghost.name = "Dodge afterimage";
            ghost.transform.SetPositionAndRotation(position, rotation);
            ghost.transform.localScale = new Vector3(0.46f, 0.92f, 0.32f);
            var collider = ghost.GetComponent<Collider>();
            if (collider != null) Destroy(collider);
            var renderer = ghost.GetComponent<Renderer>();
            var material = CreateMaterial(true);
            SetMaterialColor(material, new Color(color.r, color.g, color.b, 0.25f));
            renderer.sharedMaterial = material;
            StartCoroutine(FadeGhostRoutine(ghost, renderer, material));
        }

        public void PlaySkillCharge(Vector3 position, Color color)
        {
            EmitBurst(position, color, 70, 0.9f, -2.6f, 0.04f, 0.22f, Vector3.up);
            StartCoroutine(PulseOrbRoutine(position, color));
        }

        public void PlayDangerRing(Vector3 position, float radius, float duration)
        {
            StartCoroutine(DangerRingRoutine(position, radius, duration));
        }

        public void PlayPerfectDodge(Vector3 position, Color color)
        {
            EmitBurst(position + Vector3.up, color, 54, 0.42f, 7.5f, 0.035f, 0.2f, Vector3.up);
            PlayShockwave(position + Vector3.up, Vector3.up, 1.65f);
        }

        public void PlayShieldBreak(Vector3 position)
        {
            EmitBurst(position + Vector3.up * 1.4f, new Color(1f, 0.32f, 0.08f), 86, 0.62f, 9f, 0.05f, 0.34f, Vector3.up);
            PlayShockwave(position + Vector3.up * 1.25f, Vector3.up, 3.4f);
        }

        public void PlayPickup(Vector3 position, Color color)
        {
            EmitBurst(position, color, 38, 0.55f, 4.6f, 0.04f, 0.2f, Vector3.up);
            PlayShockwave(position, Vector3.up, 1.25f);
        }

        public void PlayMeteorImpact(Vector3 position)
        {
            EmitBurst(position + Vector3.up * 0.15f, new Color(1f, 0.24f, 0.035f), 92, 0.72f, 10f, 0.06f, 0.4f, Vector3.up);
            PlayShockwave(position + Vector3.up * 0.08f, Vector3.up, 3.1f);
        }

        public GameObject CreateEnemyOrb(Vector3 position, float size = 0.72f)
        {
            var orb = GameObject.CreatePrimitive(PrimitiveType.Sphere);
            orb.name = "Kaiju plasma orb";
            orb.transform.position = position;
            orb.transform.localScale = Vector3.one * size;
            var collider = orb.GetComponent<Collider>();
            if (collider != null) Destroy(collider);
            var renderer = orb.GetComponent<Renderer>();
            var material = CreateMaterial(true);
            SetMaterialColor(material, new Color(1f, 0.08f, 0.025f, 1f));
            renderer.sharedMaterial = material;
            EmitBurst(position, new Color(1f, 0.12f, 0.03f), 30, 0.5f, -1.8f, 0.035f, 0.16f, Vector3.up);
            return orb;
        }

        public void PlayEnemyOrbTrail(Vector3 position, Vector3 direction)
        {
            EmitBurst(position, new Color(1f, 0.12f, 0.025f), 5, 0.26f, 2.4f, 0.025f, 0.11f, -direction);
        }

        public void ExplodeEnemyOrb(GameObject orb, bool hit)
        {
            if (orb == null)
            {
                return;
            }

            var position = orb.transform.position;
            EmitBurst(position, hit ? new Color(1f, 0.16f, 0.025f) : new Color(0.65f, 0.12f, 1f), hit ? 66 : 36, 0.52f, 7f, 0.04f, 0.28f, Vector3.up);
            PlayShockwave(position, Vector3.up, hit ? 2.1f : 1.35f);
            var renderer = orb.GetComponent<Renderer>();
            if (renderer != null && renderer.sharedMaterial != null) Destroy(renderer.sharedMaterial);
            Destroy(orb);
        }

        public void PlayBeam(Vector3 origin, Vector3 direction, float length, float duration, Color color)
        {
            StartCoroutine(BeamRoutine(origin, direction.normalized, length, duration, color, true));
        }

        public void PlayPulseShot(Vector3 origin, Vector3 direction, float length, Color color, bool finisher)
        {
            StartCoroutine(BeamRoutine(origin, direction.normalized, length, finisher ? 0.24f : 0.15f, color, false));
        }

        private void EmitBurst(
            Vector3 position,
            Color color,
            int count,
            float lifetime,
            float speed,
            float minSize,
            float maxSize,
            Vector3 direction)
        {
            var effect = new GameObject("Particle burst");
            effect.transform.position = position;
            effect.transform.rotation = Quaternion.FromToRotation(
                Vector3.forward,
                direction.sqrMagnitude > 0.01f ? direction.normalized : Vector3.up);
            var particles = effect.AddComponent<ParticleSystem>();
            var renderer = particles.GetComponent<ParticleSystemRenderer>();
            renderer.sharedMaterial = _particleMaterial;

            var main = particles.main;
            main.loop = false;
            main.duration = Mathf.Max(0.1f, lifetime);
            main.startLifetime = new ParticleSystem.MinMaxCurve(lifetime * 0.55f, lifetime);
            main.startSpeed = new ParticleSystem.MinMaxCurve(speed * 0.55f, speed);
            main.startSize = new ParticleSystem.MinMaxCurve(minSize, maxSize);
            main.startColor = new ParticleSystem.MinMaxGradient(Color.white, color);
            main.simulationSpace = ParticleSystemSimulationSpace.World;
            main.maxParticles = Mathf.Max(64, count);

            var emission = particles.emission;
            emission.enabled = false;
            var shape = particles.shape;
            shape.shapeType = ParticleSystemShapeType.Cone;
            shape.angle = 38f;
            shape.radius = 0.08f;

            var trails = particles.trails;
            trails.enabled = true;
            trails.ratio = 0.55f;
            trails.lifetime = 0.13f;
            renderer.trailMaterial = _additiveMaterial;

            particles.Emit(count);
            particles.Play();
            Destroy(effect, lifetime + 0.5f);
        }

        private IEnumerator ShockwaveRoutine(Vector3 position, Vector3 forward, float maxRadius)
        {
            var effect = new GameObject("Energy shockwave");
            effect.transform.position = position;
            effect.transform.rotation = Quaternion.FromToRotation(
                Vector3.forward,
                forward.sqrMagnitude > 0.01f ? forward.normalized : Vector3.forward);
            var line = effect.AddComponent<LineRenderer>();
            line.loop = true;
            line.useWorldSpace = false;
            line.positionCount = 64;
            line.sharedMaterial = _additiveMaterial;
            line.numCornerVertices = 4;
            line.numCapVertices = 4;
            for (var i = 0; i < line.positionCount; i++)
            {
                var angle = i / (float)line.positionCount * Mathf.PI * 2f;
                line.SetPosition(i, new Vector3(Mathf.Cos(angle), Mathf.Sin(angle), 0f));
            }

            var duration = 0.36f;
            var elapsed = 0f;
            while (elapsed < duration)
            {
                elapsed += Time.deltaTime;
                var t = Mathf.Clamp01(elapsed / duration);
                var scale = Mathf.Lerp(0.15f, maxRadius, Mathf.SmoothStep(0f, 1f, t));
                effect.transform.localScale = Vector3.one * scale;
                line.startWidth = line.endWidth = Mathf.Lerp(0.16f, 0.015f, t) / Mathf.Max(0.1f, scale);
                var color = new Color(0.35f, 0.95f, 1f, 1f - t);
                line.startColor = line.endColor = color;
                yield return null;
            }
            Destroy(effect);
        }

        private IEnumerator DangerRingRoutine(Vector3 position, float radius, float duration)
        {
            var effect = new GameObject("Monster attack warning");
            effect.transform.position = position + Vector3.up * 0.035f;
            effect.transform.rotation = Quaternion.Euler(90f, 0f, 0f);
            var line = effect.AddComponent<LineRenderer>();
            line.loop = true;
            line.useWorldSpace = false;
            line.positionCount = 64;
            line.sharedMaterial = _additiveMaterial;
            line.startWidth = line.endWidth = 0.09f;
            for (var i = 0; i < line.positionCount; i++)
            {
                var angle = i / (float)line.positionCount * Mathf.PI * 2f;
                line.SetPosition(i, new Vector3(Mathf.Cos(angle) * radius, Mathf.Sin(angle) * radius, 0f));
            }

            var elapsed = 0f;
            while (elapsed < duration)
            {
                elapsed += Time.deltaTime;
                var t = Mathf.Clamp01(elapsed / Mathf.Max(0.01f, duration));
                var pulse = 0.35f + Mathf.Abs(Mathf.Sin(t * Mathf.PI * 6f)) * 0.65f;
                line.startColor = line.endColor = new Color(1f, 0.08f, 0.03f, pulse);
                effect.transform.localScale = Vector3.one * Mathf.Lerp(0.55f, 1f, t);
                yield return null;
            }
            Destroy(effect);
        }

        private IEnumerator BeamRoutine(Vector3 origin, Vector3 direction, float length, float duration, Color color, bool massive)
        {
            var beam = new GameObject("Hero energy beam");
            var core = beam.AddComponent<LineRenderer>();
            core.positionCount = 2;
            core.useWorldSpace = true;
            core.sharedMaterial = _additiveMaterial;
            core.numCapVertices = 8;
            core.SetPosition(0, origin);
            core.SetPosition(1, origin + direction * length);

            var halo = beam.AddComponent<LineRenderer>();
            halo.positionCount = 2;
            halo.useWorldSpace = true;
            halo.sharedMaterial = _additiveMaterial;
            halo.numCapVertices = 8;
            halo.SetPosition(0, origin);
            halo.SetPosition(1, origin + direction * length);

            LineRenderer spiral = null;
            if (massive)
            {
                var spiralObject = new GameObject("Spiraling beam energy");
                spiralObject.transform.SetParent(beam.transform, false);
                spiral = spiralObject.AddComponent<LineRenderer>();
                spiral.positionCount = 36;
                spiral.useWorldSpace = true;
                spiral.sharedMaterial = _additiveMaterial;
                spiral.numCapVertices = 5;
                spiral.startWidth = spiral.endWidth = 0.075f;
            }

            var side = Vector3.Cross(direction, Vector3.up);
            if (side.sqrMagnitude < 0.01f) side = Vector3.Cross(direction, Vector3.right);
            side.Normalize();
            var beamUp = Vector3.Cross(side, direction).normalized;

            var elapsed = 0f;
            while (elapsed < duration)
            {
                elapsed += Time.deltaTime;
                var t = Mathf.Clamp01(elapsed / duration);
                var pulse = Mathf.Sin(t * Mathf.PI);
                core.startWidth = (massive ? 0.22f : 0.07f) + pulse * (massive ? 0.65f : 0.24f);
                core.endWidth = (massive ? 0.12f : 0.04f) + pulse * (massive ? 0.42f : 0.14f);
                var beamColor = Color.Lerp(Color.white, color, 0.62f);
                beamColor.a = Mathf.Clamp01((1f - t) * 2.5f);
                core.startColor = core.endColor = beamColor;
                var haloColor = color;
                haloColor.a = (1f - t) * (massive ? 0.32f : 0.18f);
                halo.startColor = halo.endColor = haloColor;
                halo.startWidth = core.startWidth * (massive ? 2.5f : 1.9f);
                halo.endWidth = core.endWidth * (massive ? 2.5f : 1.9f);
                if (spiral != null)
                {
                    var spiralColor = Color.Lerp(Color.white, color, 0.35f);
                    spiralColor.a = Mathf.Clamp01((1f - t) * 2f);
                    spiral.startColor = spiral.endColor = spiralColor;
                    for (var pointIndex = 0; pointIndex < spiral.positionCount; pointIndex++)
                    {
                        var progress = pointIndex / (float)(spiral.positionCount - 1);
                        var angle = progress * Mathf.PI * 8f + elapsed * 19f;
                        var radius = Mathf.Sin(progress * Mathf.PI) * (0.26f + pulse * 0.2f);
                        spiral.SetPosition(
                            pointIndex,
                            origin + direction * (length * progress) + (side * Mathf.Cos(angle) + beamUp * Mathf.Sin(angle)) * radius);
                    }
                }
                if (Random.value < 0.42f)
                {
                    EmitBurst(origin + direction * Random.Range(0.2f, length), color, 2, 0.22f, 2f, 0.03f, 0.12f, Random.onUnitSphere);
                }
                yield return null;
            }

            if (massive)
            {
                PlayShockwave(origin + direction * length, direction, 3f);
            }
            else
            {
                EmitBurst(origin + direction * length, color, 18, 0.24f, 4.8f, 0.035f, 0.16f, direction);
                PlayShockwave(origin + direction * length, direction, 0.82f);
            }
            Destroy(beam);
        }

        private IEnumerator SlashArcRoutine(Vector3 position, Vector3 direction, Color color, float maxRadius)
        {
            var effect = new GameObject("Hero slash arc");
            var line = effect.AddComponent<LineRenderer>();
            line.positionCount = 24;
            line.useWorldSpace = true;
            line.sharedMaterial = _additiveMaterial;
            line.numCapVertices = 6;
            var forward = direction.sqrMagnitude > 0.01f ? direction.normalized : Vector3.forward;
            var side = Vector3.Cross(Vector3.up, forward).normalized;
            var elapsed = 0f;
            const float duration = 0.24f;
            while (elapsed < duration)
            {
                elapsed += Time.deltaTime;
                var t = Mathf.Clamp01(elapsed / duration);
                var radius = Mathf.Lerp(maxRadius * 0.45f, maxRadius, Mathf.SmoothStep(0f, 1f, t));
                for (var pointIndex = 0; pointIndex < line.positionCount; pointIndex++)
                {
                    var arcT = pointIndex / (float)(line.positionCount - 1);
                    var angle = Mathf.Lerp(-72f, 72f, arcT) * Mathf.Deg2Rad;
                    line.SetPosition(pointIndex, position + forward * Mathf.Cos(angle) * radius + side * Mathf.Sin(angle) * radius);
                }
                var arcColor = color;
                arcColor.a = 1f - t;
                line.startColor = line.endColor = arcColor;
                line.startWidth = line.endWidth = Mathf.Lerp(0.2f, 0.025f, t);
                yield return null;
            }
            Destroy(effect);
        }

        private IEnumerator PulseOrbRoutine(Vector3 position, Color color)
        {
            var orb = GameObject.CreatePrimitive(PrimitiveType.Sphere);
            orb.name = "Skill charge orb";
            orb.transform.position = position;
            var collider = orb.GetComponent<Collider>();
            if (collider != null) Destroy(collider);
            var renderer = orb.GetComponent<Renderer>();
            var material = CreateMaterial(true);
            renderer.sharedMaterial = material;
            var elapsed = 0f;
            const float duration = 0.7f;
            while (elapsed < duration)
            {
                elapsed += Time.deltaTime;
                var t = Mathf.Clamp01(elapsed / duration);
                var size = Mathf.Lerp(0.08f, 0.75f, t) * (1f + Mathf.Sin(t * 28f) * 0.09f);
                orb.transform.localScale = Vector3.one * size;
                SetMaterialColor(material, Color.Lerp(Color.white, color, t));
                yield return null;
            }
            Destroy(material);
            Destroy(orb);
        }

        private IEnumerator FadeGhostRoutine(GameObject ghost, Renderer renderer, Material material)
        {
            const float duration = 0.28f;
            var elapsed = 0f;
            var color = material.color;
            while (elapsed < duration)
            {
                elapsed += Time.deltaTime;
                var t = Mathf.Clamp01(elapsed / duration);
                color.a = Mathf.Lerp(0.25f, 0f, t);
                SetMaterialColor(material, color);
                ghost.transform.localScale *= 1f + Time.deltaTime * 0.45f;
                yield return null;
            }
            Destroy(material);
            Destroy(ghost);
        }

        private static Material CreateMaterial(bool additive)
        {
            var shader = (GraphicsSettings.currentRenderPipeline != null
                    ? Shader.Find("Universal Render Pipeline/Particles/Unlit")
                    : Shader.Find("Particles/Standard Unlit"))
                         ?? Shader.Find("Particles/Standard Unlit")
                         ?? Shader.Find("Sprites/Default");
            var material = new Material(shader);
            if (additive)
            {
                material.SetFloat("_Surface", 1f);
                material.SetFloat("_Blend", 1f);
                material.SetFloat("_SrcBlend", (float)UnityEngine.Rendering.BlendMode.SrcAlpha);
                material.SetFloat("_DstBlend", (float)UnityEngine.Rendering.BlendMode.One);
                material.renderQueue = 3000;
            }
            return material;
        }

        private static void SetMaterialColor(Material material, Color color)
        {
            material.color = color;
            if (material.HasProperty("_BaseColor")) material.SetColor("_BaseColor", color);
            if (material.HasProperty("_EmissionColor")) material.SetColor("_EmissionColor", color * 2f);
        }
    }
}

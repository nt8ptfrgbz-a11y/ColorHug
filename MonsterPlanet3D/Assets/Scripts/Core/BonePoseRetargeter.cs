using System;
using System.Collections.Generic;
using System.Text;
using UnityEngine;

namespace MonsterPlanet3D.Core
{
    /// <summary>
    /// Copies animation deltas from a hidden animated character to a different
    /// humanoid mesh. This keeps the lightweight Quaternius combat clips while
    /// allowing the visible hero to use proper superhero proportions.
    /// </summary>
    [DefaultExecutionOrder(150)]
    public sealed class BonePoseRetargeter : MonoBehaviour
    {
        [Serializable]
        private sealed class BoneLink
        {
            public Transform Source;
            public Transform Target;
            public Quaternion SourceRest;
            public Quaternion TargetRest;
        }

        [SerializeField] private Transform sourceRoot;
        [SerializeField] private Transform targetRoot;
        [SerializeField] private List<BoneLink> links = new List<BoneLink>();

        private static readonly Dictionary<string, string> BoneAliases = new Dictionary<string, string>
        {
            { "hips", "pelvis" },
            { "abdomen", "spine1" },
            { "torso", "spine3" },
            { "shoulderl", "claviclel" },
            { "shoulderr", "clavicler" },
            { "upperlegl", "thighl" },
            { "upperlegr", "thighr" },
            { "lowerlegl", "calfl" },
            { "lowerlegr", "calfr" }
        };

        public void Configure(Transform animationSource, Transform visibleTarget)
        {
            sourceRoot = animationSource;
            targetRoot = visibleTarget;
            BuildLinks();
        }

        private void Awake()
        {
            // Rebuild at runtime so the rest pose is captured from the live
            // instances, rather than relying on prefab references serialized
            // while the prototype scene was generated.
            BuildLinks();
        }

        private void BuildLinks()
        {
            links = new List<BoneLink>();
            if (sourceRoot == null || targetRoot == null)
            {
                return;
            }

            var targetBones = new Dictionary<string, Transform>();
            foreach (var target in targetRoot.GetComponentsInChildren<Transform>(true))
            {
                var key = Normalize(target.name);
                if (!targetBones.ContainsKey(key))
                {
                    targetBones.Add(key, target);
                }
            }

            foreach (var source in sourceRoot.GetComponentsInChildren<Transform>(true))
            {
                var key = Normalize(source.name);
                if (BoneAliases.TryGetValue(key, out var alias))
                {
                    key = alias;
                }

                if (!targetBones.TryGetValue(key, out var target) || source == sourceRoot)
                {
                    continue;
                }

                links.Add(new BoneLink
                {
                    Source = source,
                    Target = target,
                    SourceRest = source.localRotation,
                    TargetRest = target.localRotation
                });
            }
        }

        private void LateUpdate()
        {
            if (links == null)
            {
                return;
            }

            foreach (var link in links)
            {
                if (link.Source == null || link.Target == null)
                {
                    continue;
                }

                // Animation clips store their turn relative to each source
                // bone's bind orientation. Apply that local delta on the right
                // of the target bind orientation so differing FBX bone axes do
                // not twist the guardian back toward a T pose.
                var animationDelta = Quaternion.Inverse(link.SourceRest) * link.Source.localRotation;
                link.Target.localRotation = link.TargetRest * animationDelta;
            }
        }

        private static string Normalize(string value)
        {
            var builder = new StringBuilder(value.Length);
            foreach (var character in value.ToLowerInvariant())
            {
                if (char.IsLetter(character) || (char.IsDigit(character) && character != '0'))
                {
                    builder.Append(character);
                }
            }
            return builder.ToString();
        }
    }
}

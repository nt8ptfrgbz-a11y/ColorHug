#if UNITY_EDITOR
using System.IO;
using System.Linq;
using MonsterPlanet3D.CameraSystem;
using MonsterPlanet3D.Combat;
using MonsterPlanet3D.Core;
using MonsterPlanet3D.Enemy;
using MonsterPlanet3D.InputSystem;
using MonsterPlanet3D.Player;
using MonsterPlanet3D.UI;
using MonsterPlanet3D.VFX;
using UnityEditor;
using UnityEditor.Events;
using UnityEditor.Animations;
using UnityEditor.Build;
using UnityEditor.Build.Reporting;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
using UnityEngine.SceneManagement;
using UnityEngine.UI;

namespace MonsterPlanet3D.EditorTools
{
    public static class PrototypeSceneBuilder
    {
        private const string ScenePath = "Assets/Scenes/MonsterPlanetPrototype.unity";
        private const string MaterialFolder = "Assets/Generated/Materials";

        [MenuItem("Monster Planet/Build Playable Prototype")]
        public static void BuildPlayablePrototype()
        {
            EnsureFolder("Assets/Scenes");
            EnsureFolder("Assets/Generated");
            EnsureFolder(MaterialFolder);

            var scene = EditorSceneManager.NewScene(NewSceneSetup.EmptyScene, NewSceneMode.Single);

            ConfigureUrp();
            ConfigureWorld();
            var materials = CreateMaterials();
            BuildArena(materials);

            var systems = new GameObject("MonsterPlanetBridge");
            systems.AddComponent<BattleTime>();
            systems.AddComponent<MobileQualityBootstrap>();
            var battleVfx = systems.AddComponent<BattleVfx>();
            var battleAudio = systems.AddComponent<BattleAudio>();
            var voiceGuide = systems.AddComponent<VoiceGuide>();
            voiceGuide.Configure(
                AssetDatabase.LoadAssetAtPath<AudioClip>("Assets/Audio/Voice/choose.aiff"),
                AssetDatabase.LoadAssetAtPath<AudioClip>("Assets/Audio/Voice/start.aiff"),
                AssetDatabase.LoadAssetAtPath<AudioClip>("Assets/Audio/Voice/energy.aiff"),
                AssetDatabase.LoadAssetAtPath<AudioClip>("Assets/Audio/Voice/dodge.aiff"),
                AssetDatabase.LoadAssetAtPath<AudioClip>("Assets/Audio/Voice/win.aiff"),
                AssetDatabase.LoadAssetAtPath<AudioClip>("Assets/Audio/Voice/lose.aiff"));
            var director = systems.AddComponent<BattleDirector>();
            var arenaEncounter = systems.AddComponent<ArenaEncounterDirector>();
            var flutterBridge = systems.AddComponent<FlutterGameBridge>();

            var hero = BuildHero(materials);
            var monster = BuildMonster(materials);
            var cameraRig = BuildCamera(hero.Controller.transform, monster.Controller.transform);

            var hud = BuildHud(director);
            hero.Controller.SetReferences(
                hero.AttackOrigin,
                hud.Joystick,
                hero.Visual,
                battleVfx,
                battleAudio,
                cameraRig);
            monster.Controller.Configure(
                hero.Controller.transform,
                monster.Visual,
                battleVfx,
                battleAudio,
                cameraRig);
            cameraRig.Configure(hero.Controller.transform, monster.Controller.transform);
            director.Configure(hero.Controller, hero.Visual, monster.Controller, hud.Hud, voiceGuide, arenaEncounter);
            arenaEncounter.Configure(hero.Controller, hud.Hud, battleVfx, battleAudio, cameraRig);
            flutterBridge.Configure(director);

            UnityEventTools.AddPersistentListener(hud.AttackButton.onClick, hero.Controller.RequestAttack);
            UnityEventTools.AddPersistentListener(hud.DodgeButton.onClick, hero.Controller.RequestDodge);
            UnityEventTools.AddPersistentListener(hud.JumpButton.onClick, hero.Controller.RequestJump);
            UnityEventTools.AddPersistentListener(hud.SkillButton.onClick, hero.Controller.RequestSkill);
            UnityEventTools.AddPersistentListener(hud.RestartButton.onClick, director.RestartBattle);
            for (var i = 0; i < hud.HeroButtons.Length; i++)
            {
                UnityEventTools.AddIntPersistentListener(hud.HeroButtons[i].onClick, director.SelectHero, i);
            }

            EditorSceneManager.SaveScene(scene, ScenePath);
            EditorBuildSettings.scenes = new[] { new EditorBuildSettingsScene(ScenePath, true) };
            AssetDatabase.SaveAssets();
            AssetDatabase.Refresh();
            Selection.activeGameObject = hero.Controller.gameObject;
            EditorGUIUtility.PingObject(AssetDatabase.LoadAssetAtPath<SceneAsset>(ScenePath));
            Debug.Log("Monster Planet 3D prototype created at " + ScenePath);
        }

        [MenuItem("Monster Planet/Build macOS App")]
        public static void BuildMacApp()
        {
            BuildPlayablePrototype();
            Directory.CreateDirectory("Builds/macOS");
            var report = BuildPipeline.BuildPlayer(new BuildPlayerOptions
            {
                scenes = new[] { ScenePath },
                locationPathName = "Builds/macOS/MonsterPlanet3D.app",
                target = BuildTarget.StandaloneOSX,
                options = BuildOptions.None
            });
            RequireSuccessfulBuild(report, "macOS");
        }

        [MenuItem("Monster Planet/Build iOS Xcode Project")]
        public static void BuildIosProject()
        {
            BuildPlayablePrototype();
            Directory.CreateDirectory("Builds/iOS");
            ConfigureIosPlayer();
            var report = BuildPipeline.BuildPlayer(new BuildPlayerOptions
            {
                scenes = new[] { ScenePath },
                locationPathName = "Builds/iOS",
                target = BuildTarget.iOS,
                options = BuildOptions.None
            });
            RequireSuccessfulBuild(report, "iOS");
        }

        [MenuItem("Monster Planet/Export Flutter iOS Library")]
        public static void ExportFlutterIosLibrary()
        {
            if (EditorUserBuildSettings.activeBuildTarget != BuildTarget.iOS)
            {
                throw new BuildFailedException("Run this export with the iOS build target.");
            }

            BuildPlayablePrototype();
            ConfigureIosPlayer();
            ProjectExporterBatchmode.ExportProjectIos();
        }

        private static void ConfigureIosPlayer()
        {
            PlayerSettings.SetApplicationIdentifier(NamedBuildTarget.iOS, "com.colorhug.monsterplanet3d");
            PlayerSettings.SetScriptingBackend(NamedBuildTarget.iOS, ScriptingImplementation.IL2CPP);
            PlayerSettings.SetIl2CppCodeGeneration(NamedBuildTarget.iOS, Il2CppCodeGeneration.OptimizeSize);
            PlayerSettings.SetManagedStrippingLevel(NamedBuildTarget.iOS, ManagedStrippingLevel.Medium);
            PlayerSettings.productName = "Monster Planet 3D";
            PlayerSettings.companyName = "ColorHug";
            PlayerSettings.defaultInterfaceOrientation = UIOrientation.LandscapeLeft;
            PlayerSettings.allowedAutorotateToPortrait = false;
            PlayerSettings.allowedAutorotateToPortraitUpsideDown = false;
            PlayerSettings.allowedAutorotateToLandscapeLeft = true;
            PlayerSettings.allowedAutorotateToLandscapeRight = true;
            PlayerSettings.iOS.targetOSVersionString = "13.0";
            PlayerSettings.iOS.appleEnableAutomaticSigning = true;
            EditorUserBuildSettings.development = false;
            EditorUserBuildSettings.allowDebugging = false;
            EditorUserBuildSettings.connectProfiler = false;
        }

        private static void RequireSuccessfulBuild(BuildReport report, string platform)
        {
            if (report.summary.result != BuildResult.Succeeded)
            {
                throw new BuildFailedException($"Monster Planet {platform} build failed: {report.summary.result}");
            }
            Debug.Log($"Monster Planet {platform} build succeeded: {report.summary.totalSize / (1024f * 1024f):0.0} MB");
        }

        private static void ConfigureUrp()
        {
            const string rendererPath = "Assets/Generated/MonsterPlanetRenderer.asset";
            const string pipelinePath = "Assets/Generated/MonsterPlanetMobileURP.asset";
            if (AssetDatabase.LoadAssetAtPath<Object>(rendererPath) != null) AssetDatabase.DeleteAsset(rendererPath);
            if (AssetDatabase.LoadAssetAtPath<Object>(pipelinePath) != null) AssetDatabase.DeleteAsset(pipelinePath);
            GraphicsSettings.defaultRenderPipeline = null;
            QualitySettings.renderPipeline = null;
            QualitySettings.antiAliasing = 4;
            AssetDatabase.SaveAssets();
        }

        private static void ConfigureWorld()
        {
            RenderSettings.ambientMode = UnityEngine.Rendering.AmbientMode.Flat;
            RenderSettings.ambientLight = new Color(0.24f, 0.28f, 0.38f);
            RenderSettings.ambientSkyColor = new Color(0.28f, 0.33f, 0.46f);
            RenderSettings.ambientEquatorColor = new Color(0.17f, 0.21f, 0.33f);
            RenderSettings.ambientGroundColor = new Color(0.07f, 0.09f, 0.16f);
            RenderSettings.fog = true;
            RenderSettings.fogMode = FogMode.ExponentialSquared;
            RenderSettings.fogColor = new Color(0.055f, 0.085f, 0.18f);
            RenderSettings.fogDensity = 0.006f;

            var keyLightObject = new GameObject("Star Light");
            keyLightObject.transform.rotation = Quaternion.Euler(48f, -34f, 0f);
            var keyLight = keyLightObject.AddComponent<Light>();
            keyLight.type = LightType.Directional;
            keyLight.intensity = 1.3f;
            keyLight.color = new Color(0.76f, 0.87f, 1f);
            keyLight.shadows = LightShadows.Soft;

            var rimLightObject = new GameObject("Planet Rim Light");
            rimLightObject.transform.SetPositionAndRotation(new Vector3(-7f, 6f, 5f), Quaternion.identity);
            var rimLight = rimLightObject.AddComponent<Light>();
            rimLight.type = LightType.Point;
            rimLight.range = 22f;
            rimLight.intensity = 2.7f;
            rimLight.color = new Color(0.12f, 0.35f, 1f);

            var warmFillObject = new GameObject("Combat Warm Fill");
            warmFillObject.transform.position = new Vector3(6f, 5f, -4f);
            var warmFill = warmFillObject.AddComponent<Light>();
            warmFill.type = LightType.Point;
            warmFill.range = 18f;
            warmFill.intensity = 1.8f;
            warmFill.color = new Color(1f, 0.34f, 0.16f);

        }

        private static void ConfigurePostProcessing()
        {
            const string profilePath = "Assets/Generated/MonsterPlanetVolume.asset";
            if (AssetDatabase.LoadAssetAtPath<VolumeProfile>(profilePath) != null)
            {
                AssetDatabase.DeleteAsset(profilePath);
            }

            var profile = ScriptableObject.CreateInstance<VolumeProfile>();
            profile.name = "Monster Planet Mobile Volume";
            AssetDatabase.CreateAsset(profile, profilePath);

            var bloom = profile.Add<Bloom>(true);
            AssetDatabase.AddObjectToAsset(bloom, profile);
            bloom.intensity.Override(0.58f);
            bloom.threshold.Override(0.95f);

            var color = profile.Add<ColorAdjustments>(true);
            AssetDatabase.AddObjectToAsset(color, profile);
            color.contrast.Override(12f);
            color.saturation.Override(8f);
            color.postExposure.Override(0.12f);

            var vignette = profile.Add<Vignette>(true);
            AssetDatabase.AddObjectToAsset(vignette, profile);
            vignette.intensity.Override(0.23f);
            vignette.smoothness.Override(0.48f);

            var volumeObject = new GameObject("Global Battle Look");
            var volume = volumeObject.AddComponent<Volume>();
            volume.isGlobal = true;
            volume.priority = 10f;
            volume.sharedProfile = profile;
        }

        private static MaterialPalette CreateMaterials()
        {
            return new MaterialPalette
            {
                Arena = GetOrCreateMaterial("Arena", new Color(0.12f, 0.17f, 0.29f), 0.65f, 0.7f),
                ArenaEdge = GetOrCreateMaterial("ArenaEdge", new Color(0.05f, 0.32f, 0.48f), 0.35f, 0.75f, new Color(0.02f, 0.55f, 1f) * 2.2f),
                Rock = GetOrCreateMaterial("SpaceRock", new Color(0.2f, 0.22f, 0.32f), 0.05f, 0.28f),
                Crystal = GetOrCreateMaterial("Crystal", new Color(0.15f, 0.62f, 1f), 0.25f, 0.85f, new Color(0.04f, 0.55f, 1f) * 2.8f),
                Silver = GetOrCreateMaterial("HeroSilver", new Color(0.42f, 0.47f, 0.55f), 0.72f, 0.8f),
                HeroBlue = GetOrCreateMaterial("HeroBlue", new Color(0.03f, 0.45f, 0.88f), 0.35f, 0.72f),
                HeroDark = GetOrCreateMaterial("HeroDark", new Color(0.025f, 0.05f, 0.11f), 0.48f, 0.7f),
                HeroGlow = GetOrCreateMaterial("HeroGlow", new Color(0.35f, 0.95f, 1f), 0.05f, 0.9f, new Color(0.1f, 0.85f, 1f) * 4f),
                Monster = GetOrCreateMaterial("MonsterSkin", new Color(0.12f, 0.24f, 0.21f), 0.18f, 0.32f),
                MonsterArmor = GetOrCreateMaterial("MonsterArmor", new Color(0.52f, 0.065f, 0.055f), 0.48f, 0.58f),
                MonsterGlow = GetOrCreateMaterial("MonsterGlow", new Color(1f, 0.22f, 0.035f), 0.1f, 0.8f, new Color(1f, 0.035f, 0.005f) * 4.8f)
            };
        }

        private static void BuildArena(MaterialPalette materials)
        {
            var environment = new GameObject("--- MONSTER PLANET ARENA ---");
            var battlePlatform = CreatePrimitive(
                "Battle Platform",
                PrimitiveType.Cylinder,
                environment.transform,
                new Vector3(0f, -0.38f, 1f),
                new Vector3(18.4f, 0.38f, 18.4f),
                materials.Arena,
                Vector3.zero,
                true);
            // A scaled Cylinder primitive carries a CapsuleCollider. With this arena's
            // non-uniform scale PhysX turns it into a huge curved surface, which pushes
            // both fighters toward the rim. Use one flat collision volume instead.
            var groundCollider = battlePlatform.AddComponent<BoxCollider>();
            groundCollider.center = Vector3.zero;
            groundCollider.size = new Vector3(1f, 2f, 1f);
            CreatePrimitive(
                "Energy Rim",
                PrimitiveType.Cylinder,
                environment.transform,
                new Vector3(0f, -0.58f, 1f),
                new Vector3(19.3f, 0.16f, 19.3f),
                materials.ArenaEdge);

            CreatePrimitive(
                "Planet bedrock",
                PrimitiveType.Cylinder,
                environment.transform,
                new Vector3(0f, -1.08f, 1f),
                new Vector3(20.6f, 0.58f, 20.6f),
                materials.Rock,
                Vector3.zero,
                true);

            for (var ring = 1; ring <= 3; ring++)
            {
                var radius = ring * 2.35f;
                for (var i = 0; i < 16; i++)
                {
                    var angle = i / 16f * Mathf.PI * 2f;
                    var position = new Vector3(Mathf.Cos(angle) * radius, 0.025f, 1f + Mathf.Sin(angle) * radius);
                    CreatePrimitive(
                        $"Energy tile {ring}-{i}",
                        PrimitiveType.Cube,
                        environment.transform,
                        position,
                        new Vector3(0.07f, 0.025f, 0.42f),
                        materials.ArenaEdge,
                        new Vector3(0f, -angle * Mathf.Rad2Deg, 0f));
                }
            }

            for (var i = 0; i < 18; i++)
            {
                var angle = i / 18f * Mathf.PI * 2f + 0.17f;
                var radius = 11f + (i % 3) * 1.6f;
                var position = new Vector3(Mathf.Cos(angle) * radius, -0.2f, 1f + Mathf.Sin(angle) * radius);
                var rockScale = 0.7f + (i % 4) * 0.26f;
                CreatePrimitive(
                    $"Alien rock {i}",
                    i % 2 == 0 ? PrimitiveType.Sphere : PrimitiveType.Cube,
                    environment.transform,
                    position,
                    new Vector3(rockScale, rockScale * 1.45f, rockScale),
                    materials.Rock,
                    new Vector3(i * 13f, i * 31f, i * 7f));

                if (i % 3 == 0)
                {
                    CreatePrimitive(
                        $"Energy crystal {i}",
                        PrimitiveType.Cube,
                        environment.transform,
                        position + new Vector3(0.45f, 1.1f, -0.2f),
                        new Vector3(0.22f, 1.2f, 0.22f),
                        materials.Crystal,
                        new Vector3(12f, i * 17f, 28f));
                }
            }

            for (var i = 0; i < 24; i++)
            {
                var angle = i / 24f * Mathf.PI * 2f;
                var position = new Vector3(Mathf.Cos(angle) * 9.15f, 0.1f, 1f + Mathf.Sin(angle) * 9.15f);
                CreatePrimitive(
                    $"Arena beacon {i}",
                    PrimitiveType.Cylinder,
                    environment.transform,
                    position,
                    new Vector3(0.075f, i % 3 == 0 ? 0.62f : 0.28f, 0.075f),
                    materials.Crystal,
                    Vector3.zero);
            }

            var distantPlanet = CreatePrimitive(
                "Distant violet planet",
                PrimitiveType.Sphere,
                environment.transform,
                new Vector3(32f, 18f, 52f),
                new Vector3(18f, 18f, 18f),
                materials.MonsterArmor,
                Vector3.zero);
            distantPlanet.GetComponent<Renderer>().shadowCastingMode = ShadowCastingMode.Off;

            for (var i = 0; i < 72; i++)
            {
                var direction = Random.onUnitSphere;
                if (direction.y < -0.15f) direction.y = Mathf.Abs(direction.y) + 0.2f;
                var distance = Random.Range(34f, 70f);
                var star = CreatePrimitive(
                    $"Star {i}",
                    PrimitiveType.Sphere,
                    environment.transform,
                    new Vector3(0f, 7f, 1f) + direction.normalized * distance,
                    Vector3.one * Random.Range(0.05f, 0.16f),
                    i % 5 == 0 ? materials.Crystal : materials.HeroGlow,
                    Vector3.zero);
                star.GetComponent<Renderer>().shadowCastingMode = ShadowCastingMode.Off;
            }
        }

        private static HeroBuildResult BuildHero(MaterialPalette materials)
        {
            var root = new GameObject("Player - Light Guardian");
            root.transform.position = new Vector3(-2.2f, 0.05f, -3.2f);
            root.transform.rotation = Quaternion.Euler(0f, 18f, 0f);
            var controller = root.AddComponent<CharacterController>();
            controller.height = 2.65f;
            controller.radius = 0.48f;
            controller.center = new Vector3(0f, 1.32f, 0f);
            controller.stepOffset = 0.35f;
            controller.slopeLimit = 48f;
            root.AddComponent<Combatant>().Configure(105f);
            var heroController = root.AddComponent<HeroController>();

            var visualRoot = new GameObject("Procedural 3D Hero").transform;
            visualRoot.SetParent(root.transform, false);
            var bodyRig = new GameObject("Body Rig").transform;
            bodyRig.SetParent(visualRoot, false);

            var skinRenderers = new Renderer[12];
            skinRenderers[0] = CreatePrimitive("Torso", PrimitiveType.Capsule, bodyRig, new Vector3(0f, 1.48f, 0f), new Vector3(0.52f, 0.72f, 0.36f), materials.Silver).GetComponent<Renderer>();
            skinRenderers[1] = CreatePrimitive("Chest V", PrimitiveType.Cube, bodyRig, new Vector3(0f, 1.58f, 0.34f), new Vector3(0.46f, 0.34f, 0.055f), materials.HeroBlue, new Vector3(0f, 0f, 45f)).GetComponent<Renderer>();
            CreatePrimitive("Core", PrimitiveType.Sphere, bodyRig, new Vector3(0f, 1.62f, 0.46f), new Vector3(0.13f, 0.13f, 0.07f), materials.HeroGlow);

            var head = new GameObject("Head Pivot").transform;
            head.SetParent(bodyRig, false);
            head.localPosition = new Vector3(0f, 2.38f, 0f);
            skinRenderers[2] = CreatePrimitive("Helmet", PrimitiveType.Sphere, head, Vector3.zero, new Vector3(0.42f, 0.5f, 0.4f), materials.Silver).GetComponent<Renderer>();
            CreatePrimitive("Crest", PrimitiveType.Cube, head, new Vector3(0f, 0.42f, -0.04f), new Vector3(0.055f, 0.36f, 0.18f), materials.HeroBlue, new Vector3(8f, 0f, 0f));
            CreatePrimitive("Left Eye", PrimitiveType.Cube, head, new Vector3(-0.2f, 0.08f, 0.36f), new Vector3(0.16f, 0.055f, 0.035f), materials.HeroGlow, new Vector3(0f, -8f, -8f));
            CreatePrimitive("Right Eye", PrimitiveType.Cube, head, new Vector3(0.2f, 0.08f, 0.36f), new Vector3(0.16f, 0.055f, 0.035f), materials.HeroGlow, new Vector3(0f, 8f, 8f));

            var leftArm = CreateLimbPivot("Left Arm", bodyRig, new Vector3(-0.62f, 1.96f, 0f));
            var rightArm = CreateLimbPivot("Right Arm", bodyRig, new Vector3(0.62f, 1.96f, 0f));
            skinRenderers[3] = CreatePrimitive("Left Arm Mesh", PrimitiveType.Capsule, leftArm, new Vector3(0f, -0.55f, 0f), new Vector3(0.2f, 0.57f, 0.2f), materials.HeroBlue).GetComponent<Renderer>();
            skinRenderers[4] = CreatePrimitive("Right Arm Mesh", PrimitiveType.Capsule, rightArm, new Vector3(0f, -0.55f, 0f), new Vector3(0.2f, 0.57f, 0.2f), materials.Silver).GetComponent<Renderer>();
            skinRenderers[5] = CreatePrimitive("Left Hand", PrimitiveType.Sphere, leftArm, new Vector3(0f, -1.12f, 0f), new Vector3(0.24f, 0.25f, 0.24f), materials.Silver).GetComponent<Renderer>();
            skinRenderers[6] = CreatePrimitive("Right Hand", PrimitiveType.Sphere, rightArm, new Vector3(0f, -1.12f, 0f), new Vector3(0.24f, 0.25f, 0.24f), materials.Silver).GetComponent<Renderer>();

            var leftLeg = CreateLimbPivot("Left Leg", bodyRig, new Vector3(-0.27f, 0.98f, 0f));
            var rightLeg = CreateLimbPivot("Right Leg", bodyRig, new Vector3(0.27f, 0.98f, 0f));
            skinRenderers[7] = CreatePrimitive("Left Leg Mesh", PrimitiveType.Capsule, leftLeg, new Vector3(0f, -0.48f, 0f), new Vector3(0.27f, 0.64f, 0.27f), materials.Silver).GetComponent<Renderer>();
            skinRenderers[8] = CreatePrimitive("Right Leg Mesh", PrimitiveType.Capsule, rightLeg, new Vector3(0f, -0.48f, 0f), new Vector3(0.27f, 0.64f, 0.27f), materials.HeroBlue).GetComponent<Renderer>();
            skinRenderers[9] = CreatePrimitive("Left Boot", PrimitiveType.Cube, leftLeg, new Vector3(0f, -1.08f, 0.12f), new Vector3(0.26f, 0.22f, 0.38f), materials.HeroDark).GetComponent<Renderer>();
            skinRenderers[10] = CreatePrimitive("Right Boot", PrimitiveType.Cube, rightLeg, new Vector3(0f, -1.08f, 0.12f), new Vector3(0.26f, 0.22f, 0.38f), materials.HeroDark).GetComponent<Renderer>();
            skinRenderers[11] = CreatePrimitive("Belt", PrimitiveType.Cylinder, bodyRig, new Vector3(0f, 0.98f, 0f), new Vector3(0.46f, 0.08f, 0.35f), materials.HeroDark).GetComponent<Renderer>();

            var visual = visualRoot.gameObject.AddComponent<ProceduralHeroVisual>();
            visual.Configure(bodyRig, head, leftArm, rightArm, leftLeg, rightLeg, skinRenderers, new Color(0.05f, 0.82f, 1f), Color.white);
            BuildExternalHeroModels(visualRoot, visual, materials);

            var attackOrigin = new GameObject("Attack Origin").transform;
            attackOrigin.SetParent(root.transform, false);
            attackOrigin.localPosition = new Vector3(0f, 1.22f, 0.58f);

            return new HeroBuildResult
            {
                Controller = heroController,
                Visual = visual,
                AttackOrigin = attackOrigin
            };
        }

        private static MonsterBuildResult BuildMonster(MaterialPalette materials)
        {
            var root = new GameObject("Enemy - Rockhorn Kaiju");
            root.transform.position = new Vector3(1.2f, 0.05f, 5.2f);
            root.transform.rotation = Quaternion.Euler(0f, 198f, 0f);
            var controller = root.AddComponent<CharacterController>();
            controller.height = 4.2f;
            controller.radius = 1.05f;
            controller.center = new Vector3(0f, 2.1f, 0f);
            controller.stepOffset = 0.42f;
            root.AddComponent<Combatant>().Configure(230f);
            var kaijuController = root.AddComponent<KaijuController>();

            var visualRoot = new GameObject("Procedural 3D Kaiju").transform;
            visualRoot.SetParent(root.transform, false);
            var bodyRig = new GameObject("Body Rig").transform;
            bodyRig.SetParent(visualRoot, false);
            CreatePrimitive("Massive Torso", PrimitiveType.Sphere, bodyRig, new Vector3(0f, 2.18f, 0f), new Vector3(1.36f, 1.48f, 1.04f), materials.Monster);
            CreatePrimitive("Chest Armor", PrimitiveType.Cube, bodyRig, new Vector3(0f, 2.45f, 0.9f), new Vector3(1.18f, 0.72f, 0.18f), materials.MonsterArmor, new Vector3(8f, 0f, 0f));
            CreatePrimitive("Chest Core", PrimitiveType.Sphere, bodyRig, new Vector3(0f, 2.55f, 0.94f), new Vector3(0.18f, 0.18f, 0.09f), materials.MonsterGlow);

            for (var spikeIndex = 0; spikeIndex < 4; spikeIndex++)
            {
                CreatePrimitive(
                    $"Dorsal Blade {spikeIndex}",
                    PrimitiveType.Cube,
                    bodyRig,
                    new Vector3(0f, 3.08f - spikeIndex * 0.58f, -0.96f - spikeIndex * 0.08f),
                    new Vector3(0.18f, 0.48f - spikeIndex * 0.05f, 0.5f),
                    materials.MonsterArmor,
                    new Vector3(45f, 0f, 0f));
            }

            var head = new GameObject("Head Pivot").transform;
            head.SetParent(bodyRig, false);
            head.localPosition = new Vector3(0f, 3.78f, 0.14f);
            CreatePrimitive("Kaiju Head", PrimitiveType.Sphere, head, Vector3.zero, new Vector3(0.92f, 0.7f, 0.92f), materials.Monster);
            CreatePrimitive("Muzzle", PrimitiveType.Cube, head, new Vector3(0f, -0.18f, 0.82f), new Vector3(0.68f, 0.32f, 0.48f), materials.MonsterArmor);
            CreatePrimitive("Left Eye", PrimitiveType.Sphere, head, new Vector3(-0.28f, 0.12f, 0.65f), new Vector3(0.12f, 0.08f, 0.07f), materials.MonsterGlow);
            CreatePrimitive("Right Eye", PrimitiveType.Sphere, head, new Vector3(0.28f, 0.12f, 0.65f), new Vector3(0.12f, 0.08f, 0.07f), materials.MonsterGlow);
            CreatePrimitive("Left Horn", PrimitiveType.Cylinder, head, new Vector3(-0.42f, 0.58f, 0f), new Vector3(0.13f, 0.48f, 0.13f), materials.MonsterArmor, new Vector3(0f, 0f, -28f));
            CreatePrimitive("Right Horn", PrimitiveType.Cylinder, head, new Vector3(0.42f, 0.58f, 0f), new Vector3(0.13f, 0.48f, 0.13f), materials.MonsterArmor, new Vector3(0f, 0f, 28f));

            for (var toothIndex = 0; toothIndex < 4; toothIndex++)
            {
                CreatePrimitive(
                    $"Fang {toothIndex}",
                    PrimitiveType.Cube,
                    head,
                    new Vector3(-0.42f + toothIndex * 0.28f, -0.35f, 1.25f),
                    new Vector3(0.055f, 0.16f, 0.055f),
                    materials.Silver,
                    new Vector3(0f, 0f, toothIndex < 2 ? -12f : 12f));
            }

            var leftArm = CreateLimbPivot("Left Claw", bodyRig, new Vector3(-1.34f, 3.02f, 0f));
            var rightArm = CreateLimbPivot("Right Claw", bodyRig, new Vector3(1.34f, 3.02f, 0f));
            CreatePrimitive("Left Shoulder Plate", PrimitiveType.Sphere, leftArm, Vector3.zero, new Vector3(0.62f, 0.44f, 0.62f), materials.MonsterArmor);
            CreatePrimitive("Right Shoulder Plate", PrimitiveType.Sphere, rightArm, Vector3.zero, new Vector3(0.62f, 0.44f, 0.62f), materials.MonsterArmor);
            CreatePrimitive("Left Arm", PrimitiveType.Capsule, leftArm, new Vector3(0f, -0.82f, 0f), new Vector3(0.48f, 0.92f, 0.48f), materials.Monster);
            CreatePrimitive("Right Arm", PrimitiveType.Capsule, rightArm, new Vector3(0f, -0.82f, 0f), new Vector3(0.48f, 0.92f, 0.48f), materials.Monster);
            CreatePrimitive("Left Fist", PrimitiveType.Sphere, leftArm, new Vector3(0f, -1.72f, 0.08f), new Vector3(0.66f, 0.58f, 0.68f), materials.MonsterArmor);
            CreatePrimitive("Right Fist", PrimitiveType.Sphere, rightArm, new Vector3(0f, -1.72f, 0.08f), new Vector3(0.66f, 0.58f, 0.68f), materials.MonsterArmor);

            var leftLeg = CreateLimbPivot("Left Leg", bodyRig, new Vector3(-0.58f, 1.35f, 0f));
            var rightLeg = CreateLimbPivot("Right Leg", bodyRig, new Vector3(0.58f, 1.35f, 0f));
            CreatePrimitive("Left Leg Mesh", PrimitiveType.Capsule, leftLeg, new Vector3(0f, -0.62f, 0f), new Vector3(0.58f, 0.8f, 0.58f), materials.Monster);
            CreatePrimitive("Right Leg Mesh", PrimitiveType.Capsule, rightLeg, new Vector3(0f, -0.62f, 0f), new Vector3(0.58f, 0.8f, 0.58f), materials.Monster);
            CreatePrimitive("Left Foot", PrimitiveType.Cube, leftLeg, new Vector3(0f, -1.34f, 0.38f), new Vector3(0.64f, 0.28f, 0.9f), materials.MonsterArmor);
            CreatePrimitive("Right Foot", PrimitiveType.Cube, rightLeg, new Vector3(0f, -1.34f, 0.38f), new Vector3(0.64f, 0.28f, 0.9f), materials.MonsterArmor);

            var tail = new GameObject("Tail Pivot").transform;
            tail.SetParent(bodyRig, false);
            tail.localPosition = new Vector3(0f, 1.7f, -0.7f);
            for (var i = 0; i < 4; i++)
            {
                CreatePrimitive(
                    $"Tail segment {i}",
                    PrimitiveType.Capsule,
                    tail,
                    new Vector3(0f, -0.12f * i, -0.52f - i * 0.55f),
                    new Vector3(0.35f - i * 0.055f, 0.42f, 0.35f - i * 0.055f),
                    materials.MonsterArmor,
                    new Vector3(90f, 0f, 0f));
            }

            var visual = visualRoot.gameObject.AddComponent<ProceduralKaijuVisual>();
            visual.Configure(bodyRig, head, leftArm, rightArm, leftLeg, rightLeg, tail);
            BuildExternalMonsterModel(visualRoot, visual, materials);
            return new MonsterBuildResult { Controller = kaijuController, Visual = visual };
        }

        private static void BuildExternalHeroModels(Transform parent, ProceduralHeroVisual visual, MaterialPalette materials)
        {
            var models = new[]
            {
                TryBuildRetargetedHeroVariant("Aurora Guardian", parent, materials, 0),
                TryBuildRetargetedHeroVariant("Nova Guardian", parent, materials, 1),
                TryBuildRetargetedHeroVariant("Sol Guardian", parent, materials, 2)
            }.Where(model => model != null).ToArray();

            if (models.Length == 3)
            {
                visual.ConfigureExternalModels(models);
            }
            else
            {
                foreach (var model in models) Object.DestroyImmediate(model.gameObject);
                Debug.LogWarning("Animated hero assets were not ready. The procedural 3D hero remains active; rebuild the scene after glTF import finishes.");
            }
        }

        private static ExternalAnimationDriver TryBuildRetargetedHeroVariant(
            string instanceName,
            Transform parent,
            MaterialPalette materials,
            int skinIndex)
        {
            const string visiblePath = "Assets/ThirdParty/Quaternius/UniversalBase/Superhero_Male_FullBody.fbx";
            const string motionPath = "Assets/ThirdParty/Quaternius/reclaimer-finn.gltf";
            var visiblePrefab = AssetDatabase.LoadAssetAtPath<GameObject>(visiblePath);
            var motionPrefab = AssetDatabase.LoadAssetAtPath<GameObject>(motionPath);
            if (visiblePrefab == null || motionPrefab == null)
            {
                return null;
            }

            var wrapper = new GameObject(instanceName);
            wrapper.transform.SetParent(parent, false);

            var visible = PrefabUtility.InstantiatePrefab(visiblePrefab, wrapper.transform) as GameObject;
            if (visible == null) visible = Object.Instantiate(visiblePrefab, wrapper.transform);
            visible.name = "Visible Light Guardian";
            visible.transform.localPosition = Vector3.zero;
            visible.transform.localRotation = Quaternion.identity;
            visible.transform.localScale = Vector3.one * 1.46f;
            foreach (var animator in visible.GetComponentsInChildren<Animator>(true)) animator.enabled = false;
            foreach (var collider in visible.GetComponentsInChildren<Collider>(true)) Object.DestroyImmediate(collider);
            StyleGuardianBaseModel(visible, materials);

            var motionSource = PrefabUtility.InstantiatePrefab(motionPrefab, wrapper.transform) as GameObject;
            if (motionSource == null) motionSource = Object.Instantiate(motionPrefab, wrapper.transform);
            motionSource.name = "Hidden Motion Source";
            motionSource.transform.localPosition = Vector3.zero;
            motionSource.transform.localRotation = Quaternion.identity;
            motionSource.transform.localScale = Vector3.one;
            foreach (var renderer in motionSource.GetComponentsInChildren<Renderer>(true)) renderer.enabled = false;
            foreach (var collider in motionSource.GetComponentsInChildren<Collider>(true)) Object.DestroyImmediate(collider);

            var animatorSource = motionSource.GetComponent<Animator>() ?? motionSource.AddComponent<Animator>();
            animatorSource.applyRootMotion = false;
            // The source meshes are deliberately invisible, but their bones
            // must keep animating because they drive the visible guardian.
            animatorSource.cullingMode = AnimatorCullingMode.AlwaysAnimate;
            animatorSource.runtimeAnimatorController = CreateAnimatorController(motionPath, instanceName + " Motion", "Idle");
            if (animatorSource.runtimeAnimatorController == null)
            {
                Object.DestroyImmediate(wrapper);
                return null;
            }

            var retargeter = wrapper.AddComponent<BonePoseRetargeter>();
            retargeter.Configure(motionSource.transform, visible.transform);
            var guardianPose = wrapper.AddComponent<GuardianPoseAnimator>();
            guardianPose.Configure(visible.transform);
            var driver = wrapper.AddComponent<ExternalAnimationDriver>();
            driver.Configure(animatorSource, "Idle", "Run", "Jump", "Punch", "Weapon", "HitReact", "Death");
            AddLightGuardianArmor(visible.transform, materials, skinIndex);
            return driver;
        }

        private static void StyleGuardianBaseModel(GameObject visible, MaterialPalette materials)
        {
            foreach (var targetRenderer in visible.GetComponentsInChildren<Renderer>(true))
            {
                if (targetRenderer.name.IndexOf("Eyebrow", System.StringComparison.OrdinalIgnoreCase) >= 0)
                {
                    targetRenderer.enabled = false;
                    continue;
                }

                var material = targetRenderer.name.IndexOf("Eye", System.StringComparison.OrdinalIgnoreCase) >= 0
                    ? materials.HeroGlow
                    : materials.Silver;
                var assigned = new Material[Mathf.Max(1, targetRenderer.sharedMaterials.Length)];
                for (var i = 0; i < assigned.Length; i++) assigned[i] = material;
                targetRenderer.sharedMaterials = assigned;
            }
        }

        private static void AddLightGuardianArmor(Transform modelRoot, MaterialPalette materials, int skinIndex)
        {
            var primary = skinIndex == 0
                ? materials.HeroBlue
                : (skinIndex == 1
                    ? GetOrCreateMaterial("HeroNova", new Color(0.16f, 0.2f, 0.92f), 0.46f, 0.76f, new Color(0.08f, 0.25f, 1f) * 1.6f)
                    : GetOrCreateMaterial("HeroSolar", new Color(0.92f, 0.055f, 0.025f), 0.42f, 0.72f, new Color(1f, 0.12f, 0.025f) * 1.4f));
            var glow = skinIndex == 2
                ? GetOrCreateMaterial("HeroSolarGlow", new Color(1f, 0.62f, 0.08f), 0.05f, 0.9f, new Color(1f, 0.28f, 0.015f) * 5f)
                : materials.HeroGlow;
            var headBone = FindDescendant(modelRoot, "Head");
            if (headBone != null)
            {
                CreateBoneAccessory("Light Helmet", PrimitiveType.Sphere, modelRoot, headBone, new Vector3(0f, 0.025f, 0f), new Vector3(0.35f, 0.44f, 0.35f), materials.Silver);
                CreateBoneAccessory("Light Crest", PrimitiveType.Cube, modelRoot, headBone, new Vector3(0f, 0.39f, -0.025f), new Vector3(0.045f, 0.27f, 0.12f), primary, new Vector3(8f, 0f, 0f));
                CreateBoneAccessory("Light Ear Left", PrimitiveType.Cube, modelRoot, headBone, new Vector3(-0.34f, 0.02f, -0.01f), new Vector3(0.07f, 0.15f, 0.12f), primary, new Vector3(0f, 0f, -18f));
                CreateBoneAccessory("Light Ear Right", PrimitiveType.Cube, modelRoot, headBone, new Vector3(0.34f, 0.02f, -0.01f), new Vector3(0.07f, 0.15f, 0.12f), primary, new Vector3(0f, 0f, 18f));
                CreateBoneAccessory("Light Eye Left", PrimitiveType.Cube, modelRoot, headBone, new Vector3(-0.145f, 0.075f, 0.32f), new Vector3(0.12f, 0.045f, 0.025f), glow, new Vector3(0f, -6f, -13f));
                CreateBoneAccessory("Light Eye Right", PrimitiveType.Cube, modelRoot, headBone, new Vector3(0.145f, 0.075f, 0.32f), new Vector3(0.12f, 0.045f, 0.025f), glow, new Vector3(0f, 6f, 13f));
            }

            var torsoBone = FindDescendant(modelRoot, "spine_03") ?? FindDescendant(modelRoot, "Torso") ?? FindDescendant(modelRoot, "Chest");
            if (torsoBone != null)
            {
                CreateBoneAccessory("Light Chest Left", PrimitiveType.Cube, modelRoot, torsoBone, new Vector3(-0.14f, 0.045f, 0.23f), new Vector3(0.23f, 0.055f, 0.025f), primary, new Vector3(0f, 0f, -32f));
                CreateBoneAccessory("Light Chest Right", PrimitiveType.Cube, modelRoot, torsoBone, new Vector3(0.14f, 0.045f, 0.23f), new Vector3(0.23f, 0.055f, 0.025f), primary, new Vector3(0f, 0f, 32f));
                CreateBoneAccessory("Light Energy Core", PrimitiveType.Sphere, modelRoot, torsoBone, new Vector3(0f, -0.03f, 0.255f), new Vector3(0.105f, 0.105f, 0.045f), glow);
            }

            var pelvisBone = FindDescendant(modelRoot, "pelvis");
            if (pelvisBone != null)
            {
                CreateBoneAccessory("Light Belt", PrimitiveType.Cylinder, modelRoot, pelvisBone, new Vector3(0f, 0.11f, 0f), new Vector3(0.31f, 0.035f, 0.24f), primary);
                CreateBoneAccessory("Light Belt Core", PrimitiveType.Sphere, modelRoot, pelvisBone, new Vector3(0f, 0.11f, 0.245f), new Vector3(0.075f, 0.075f, 0.035f), glow);
            }

            AddGuardianJointArmor(modelRoot, "upperarm_l", "Light Shoulder Left", new Vector3(0.17f, 0.13f, 0.17f), primary);
            AddGuardianJointArmor(modelRoot, "upperarm_r", "Light Shoulder Right", new Vector3(0.17f, 0.13f, 0.17f), primary);
            AddGuardianJointArmor(modelRoot, "forearm_l", "Light Bracer Left", new Vector3(0.13f, 0.17f, 0.13f), primary);
            AddGuardianJointArmor(modelRoot, "forearm_r", "Light Bracer Right", new Vector3(0.13f, 0.17f, 0.13f), primary);
            AddGuardianJointArmor(modelRoot, "calf_l", "Light Knee Left", new Vector3(0.15f, 0.12f, 0.16f), primary);
            AddGuardianJointArmor(modelRoot, "calf_r", "Light Knee Right", new Vector3(0.15f, 0.12f, 0.16f), primary);
        }

        private static void AddGuardianJointArmor(
            Transform modelRoot,
            string boneName,
            string accessoryName,
            Vector3 scale,
            Material material)
        {
            var bone = FindDescendant(modelRoot, boneName);
            if (bone != null)
            {
                CreateBoneAccessory(accessoryName, PrimitiveType.Sphere, modelRoot, bone, Vector3.zero, scale, material);
            }
        }

        private static GameObject CreateBoneAccessory(
            string name,
            PrimitiveType primitiveType,
            Transform modelRoot,
            Transform targetBone,
            Vector3 positionOffset,
            Vector3 scale,
            Material material,
            Vector3 rotationOffset = default)
        {
            var accessoryParent = modelRoot.parent != null ? modelRoot.parent : modelRoot;
            var accessory = CreatePrimitive(name, primitiveType, accessoryParent, Vector3.zero, scale, material);
            accessory.AddComponent<BoneAccessoryFollower>().Configure(targetBone, positionOffset, rotationOffset, scale);
            return accessory;
        }

        private static Transform FindDescendant(Transform root, string targetName)
        {
            foreach (var child in root.GetComponentsInChildren<Transform>(true))
            {
                if (child.name == targetName)
                {
                    return child;
                }
            }
            return null;
        }

        private static void BuildExternalMonsterModel(Transform parent, ProceduralKaijuVisual visual, MaterialPalette materials)
        {
            var model = TryInstantiateAnimatedModel(
                "Assets/ThirdParty/Quaternius/dino-kaiju.gltf",
                "Rockhorn Dino Kaiju",
                parent,
                Vector3.zero,
                1.95f,
                "Idle", "Run", "Jump", "Punch", "Weapon", "HitReact", "Death");
            if (model != null)
            {
                StyleKaijuModel(model.gameObject, materials);
                AddRockhornKaijuFeatures(model.transform, materials);
                visual.ConfigureExternalModel(model);
            }
            else
            {
                Debug.LogWarning("Animated monster asset was not ready. The procedural 3D kaiju remains active.");
            }
        }

        private static void StyleKaijuModel(GameObject model, MaterialPalette materials)
        {
            foreach (var targetRenderer in model.GetComponentsInChildren<Renderer>(true))
            {
                var assigned = targetRenderer.sharedMaterials;
                if (assigned.Length == 0)
                {
                    targetRenderer.sharedMaterial = materials.Monster;
                    continue;
                }

                for (var i = 0; i < assigned.Length; i++)
                {
                    var material = assigned[i];
                    if (material == null)
                    {
                        assigned[i] = materials.Monster;
                        continue;
                    }

                    // Preserve the original creature atlas so the model keeps
                    // its scales, teeth and facial detail, then recolor it into
                    // an original dark-jade tokusatsu kaiju skin.
                    var skin = new Color(0.38f, 0.52f, 0.29f, 1f);
                    if (material.HasProperty("_Color")) material.SetColor("_Color", skin);
                    if (material.HasProperty("_BaseColor")) material.SetColor("_BaseColor", skin);
                    if (material.HasProperty("_EmissionColor")) material.SetColor("_EmissionColor", new Color(0.012f, 0.035f, 0.022f));
                    if (material.HasProperty("_RimColor")) material.SetColor("_RimColor", new Color(0.72f, 0.12f, 0.055f));
                    if (material.HasProperty("_Metallic")) material.SetFloat("_Metallic", 0.16f);
                    if (material.HasProperty("_Glossiness")) material.SetFloat("_Glossiness", 0.42f);
                    EditorUtility.SetDirty(material);
                }
                targetRenderer.sharedMaterials = assigned;
            }
        }

        private static void AddRockhornKaijuFeatures(Transform modelRoot, MaterialPalette materials)
        {
            var headBone = FindDescendant(modelRoot, "Head");
            if (headBone != null)
            {
                CreateBoneAccessory("Kaiju Brow Armor", PrimitiveType.Cube, modelRoot, headBone, new Vector3(0f, 0.24f, 0.36f), new Vector3(0.68f, 0.19f, 0.2f), materials.MonsterArmor, new Vector3(7f, 0f, 0f));
                CreateBoneAccessory("Kaiju Crown Horn", PrimitiveType.Cylinder, modelRoot, headBone, new Vector3(0f, 0.5f, 0.05f), new Vector3(0.17f, 0.75f, 0.17f), materials.MonsterArmor, new Vector3(-28f, 0f, 0f));
                CreateBoneAccessory("Kaiju Horn Left", PrimitiveType.Cylinder, modelRoot, headBone, new Vector3(-0.38f, 0.35f, 0.02f), new Vector3(0.15f, 0.58f, 0.15f), materials.MonsterArmor, new Vector3(0f, 0f, -42f));
                CreateBoneAccessory("Kaiju Horn Right", PrimitiveType.Cylinder, modelRoot, headBone, new Vector3(0.38f, 0.35f, 0.02f), new Vector3(0.15f, 0.58f, 0.15f), materials.MonsterArmor, new Vector3(0f, 0f, 42f));
                CreateBoneAccessory("Kaiju Eye Left", PrimitiveType.Cube, modelRoot, headBone, new Vector3(-0.19f, 0.12f, 0.52f), new Vector3(0.14f, 0.045f, 0.028f), materials.MonsterGlow, new Vector3(0f, -7f, -10f));
                CreateBoneAccessory("Kaiju Eye Right", PrimitiveType.Cube, modelRoot, headBone, new Vector3(0.19f, 0.12f, 0.52f), new Vector3(0.14f, 0.045f, 0.028f), materials.MonsterGlow, new Vector3(0f, 7f, 10f));
                for (var tooth = 0; tooth < 4; tooth++)
                {
                    CreateBoneAccessory(
                        $"Kaiju Fang {tooth}",
                        PrimitiveType.Cube,
                        modelRoot,
                        headBone,
                        new Vector3(-0.24f + tooth * 0.16f, -0.13f, 0.58f),
                        new Vector3(0.035f, 0.11f, 0.035f),
                        materials.Silver,
                        new Vector3(0f, 0f, tooth < 2 ? -9f : 9f));
                }
            }

            var torsoBone = FindDescendant(modelRoot, "Torso");
            var abdomenBone = FindDescendant(modelRoot, "Abdomen");
            if (torsoBone != null)
            {
                CreateBoneAccessory("Kaiju Chest Furnace", PrimitiveType.Sphere, modelRoot, torsoBone, new Vector3(0f, 0.02f, 0.48f), new Vector3(0.28f, 0.28f, 0.1f), materials.MonsterGlow);
                CreateBoneAccessory("Kaiju Dorsal Blade High", PrimitiveType.Cube, modelRoot, torsoBone, new Vector3(0f, 0.2f, -0.45f), new Vector3(0.12f, 0.43f, 0.36f), materials.MonsterArmor, new Vector3(42f, 0f, 0f));
            }
            var leftShoulder = FindDescendant(modelRoot, "Shoulder.L");
            var rightShoulder = FindDescendant(modelRoot, "Shoulder.R");
            if (leftShoulder != null)
            {
                CreateBoneAccessory("Kaiju Shoulder Armor Left", PrimitiveType.Sphere, modelRoot, leftShoulder, Vector3.zero, new Vector3(0.42f, 0.3f, 0.46f), materials.MonsterArmor);
            }
            if (rightShoulder != null)
            {
                CreateBoneAccessory("Kaiju Shoulder Armor Right", PrimitiveType.Sphere, modelRoot, rightShoulder, Vector3.zero, new Vector3(0.42f, 0.3f, 0.46f), materials.MonsterArmor);
            }
            if (abdomenBone != null)
            {
                CreateBoneAccessory("Kaiju Dorsal Blade Low", PrimitiveType.Cube, modelRoot, abdomenBone, new Vector3(0f, 0.02f, -0.38f), new Vector3(0.1f, 0.34f, 0.3f), materials.MonsterArmor, new Vector3(42f, 0f, 0f));
            }
        }

        private static ExternalAnimationDriver TryInstantiateAnimatedModel(
            string modelPath,
            string instanceName,
            Transform parent,
            Vector3 localPosition,
            float scale,
            string idle,
            string move,
            string jump,
            string attack,
            string skill,
            string hit,
            string death)
        {
            var prefab = AssetDatabase.LoadAssetAtPath<GameObject>(modelPath);
            if (prefab == null)
            {
                return null;
            }

            var instance = PrefabUtility.InstantiatePrefab(prefab, parent) as GameObject;
            if (instance == null)
            {
                instance = Object.Instantiate(prefab, parent);
            }
            instance.name = instanceName;
            instance.transform.localPosition = localPosition;
            instance.transform.localRotation = Quaternion.identity;
            instance.transform.localScale = Vector3.one * scale;

            foreach (var collider in instance.GetComponentsInChildren<Collider>(true))
            {
                Object.DestroyImmediate(collider);
            }

            ConvertExternalModelMaterials(instance, instanceName);

            var animator = instance.GetComponent<Animator>() ?? instance.AddComponent<Animator>();
            animator.applyRootMotion = false;
            animator.runtimeAnimatorController = CreateAnimatorController(modelPath, instanceName, idle);
            if (animator.runtimeAnimatorController == null)
            {
                Object.DestroyImmediate(instance);
                return null;
            }

            var driver = instance.GetComponent<ExternalAnimationDriver>() ?? instance.AddComponent<ExternalAnimationDriver>();
            driver.Configure(animator, idle, move, jump, attack, skill, hit, death);
            return driver;
        }

        private static void ConvertExternalModelMaterials(GameObject instance, string instanceName)
        {
            var standard = Shader.Find("MonsterPlanet/Stylized") ?? Shader.Find("Standard");
            if (standard == null) return;

            var renderers = instance.GetComponentsInChildren<Renderer>(true);
            for (var rendererIndex = 0; rendererIndex < renderers.Length; rendererIndex++)
            {
                var sourceMaterials = renderers[rendererIndex].sharedMaterials;
                var converted = new Material[sourceMaterials.Length];
                for (var materialIndex = 0; materialIndex < sourceMaterials.Length; materialIndex++)
                {
                    var source = sourceMaterials[materialIndex];
                    if (source == null) continue;

                    var safeModel = new string(instanceName.Select(ch => char.IsLetterOrDigit(ch) ? ch : '_').ToArray());
                    var path = $"{MaterialFolder}/{safeModel}_{rendererIndex}_{materialIndex}.mat";
                    var material = AssetDatabase.LoadAssetAtPath<Material>(path);
                    if (material == null)
                    {
                        material = new Material(standard) { name = $"{safeModel}_{source.name}" };
                        AssetDatabase.CreateAsset(material, path);
                    }
                    else
                    {
                        material.shader = standard;
                    }

                    var color = source.HasProperty("baseColorFactor")
                        ? source.GetColor("baseColorFactor")
                        : source.HasProperty("_BaseColor")
                        ? source.GetColor("_BaseColor")
                        : source.HasProperty("_Color") ? source.GetColor("_Color") : Color.white;
                    var texture = source.HasProperty("baseColorTexture")
                        ? source.GetTexture("baseColorTexture")
                        : source.HasProperty("_BaseColorTexture")
                        ? source.GetTexture("_BaseColorTexture")
                        : source.HasProperty("_BaseMap")
                            ? source.GetTexture("_BaseMap")
                            : source.HasProperty("_MainTex") ? source.GetTexture("_MainTex") : null;
                    var normal = source.HasProperty("_NormalTexture")
                        ? source.GetTexture("_NormalTexture")
                        : source.HasProperty("_BumpMap") ? source.GetTexture("_BumpMap") : null;

                    material.color = color;
                    material.mainTexture = texture;
                    if (source.HasProperty("baseColorTexture_ST"))
                    {
                        var transform = source.GetVector("baseColorTexture_ST");
                        material.mainTextureScale = new Vector2(transform.x, transform.y);
                        material.mainTextureOffset = new Vector2(transform.z, transform.w);
                    }
                    material.SetFloat("_Metallic", source.HasProperty("_Metallic") ? source.GetFloat("_Metallic") : 0.08f);
                    material.SetFloat("_Glossiness", 0.48f);
                    material.SetColor("_EmissionColor", color * 0.24f);
                    material.EnableKeyword("_EMISSION");
                    if (normal != null)
                    {
                        material.SetTexture("_BumpMap", normal);
                        material.EnableKeyword("_NORMALMAP");
                    }
                    EditorUtility.SetDirty(material);
                    converted[materialIndex] = material;
                }
                renderers[rendererIndex].sharedMaterials = converted;
            }
        }

        private static RuntimeAnimatorController CreateAnimatorController(string modelPath, string name, string idleState)
        {
            var clips = AssetDatabase.LoadAllAssetsAtPath(modelPath)
                .OfType<AnimationClip>()
                .Where(clip => !clip.name.StartsWith("__preview__"))
                .ToArray();
            if (clips.Length == 0)
            {
                return null;
            }

            EnsureFolder("Assets/Generated/Controllers");
            var safeName = name.Replace(' ', '_');
            var controllerPath = $"Assets/Generated/Controllers/{safeName}.controller";
            if (AssetDatabase.LoadAssetAtPath<AnimatorController>(controllerPath) != null)
            {
                AssetDatabase.DeleteAsset(controllerPath);
            }

            var controller = AnimatorController.CreateAnimatorControllerAtPath(controllerPath);
            var stateMachine = controller.layers[0].stateMachine;
            AnimatorState defaultState = null;
            foreach (var clip in clips)
            {
                var state = stateMachine.AddState(clip.name);
                state.motion = clip;
                state.writeDefaultValues = true;
                if (clip.name == idleState) defaultState = state;
            }
            if (defaultState != null) stateMachine.defaultState = defaultState;
            EditorUtility.SetDirty(controller);
            return controller;
        }

        private static CombatCamera BuildCamera(Transform hero, Transform monster)
        {
            var cameraObject = new GameObject("Main Camera");
            cameraObject.tag = "MainCamera";
            cameraObject.transform.position = new Vector3(-1.4f, 5.6f, -10.8f);
            cameraObject.transform.LookAt(hero.position + Vector3.up * 1.3f);
            var camera = cameraObject.AddComponent<UnityEngine.Camera>();
            camera.fieldOfView = 52f;
            camera.nearClipPlane = 0.08f;
            camera.farClipPlane = 160f;
            camera.allowHDR = true;
            camera.useOcclusionCulling = false;
            camera.renderingPath = RenderingPath.Forward;
            camera.clearFlags = CameraClearFlags.SolidColor;
            camera.backgroundColor = new Color(0.035f, 0.065f, 0.16f);
            cameraObject.AddComponent<AudioListener>();
            var combatCamera = cameraObject.AddComponent<CombatCamera>();
            combatCamera.Configure(hero, monster);
            return combatCamera;
        }

        private static HudBuildResult BuildHud(BattleDirector director)
        {
            var font = Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");
            var canvasObject = new GameObject("Mobile Battle UI");
            var canvas = canvasObject.AddComponent<Canvas>();
            canvas.renderMode = RenderMode.ScreenSpaceOverlay;
            canvas.sortingOrder = 10;
            var scaler = canvasObject.AddComponent<CanvasScaler>();
            scaler.uiScaleMode = CanvasScaler.ScaleMode.ScaleWithScreenSize;
            scaler.referenceResolution = new Vector2(1920f, 1080f);
            scaler.matchWidthOrHeight = 0.5f;
            canvasObject.AddComponent<GraphicRaycaster>();

            var eventSystem = new GameObject("EventSystem");
            eventSystem.AddComponent<EventSystem>();
            eventSystem.AddComponent<StandaloneInputModule>();

            var damageOverlayObject = CreateUiObject("Damage Vignette", canvasObject.transform);
            StretchFullScreen(damageOverlayObject.GetComponent<RectTransform>());
            var damageOverlay = damageOverlayObject.AddComponent<Image>();
            damageOverlay.color = Color.clear;
            damageOverlay.raycastTarget = false;

            var heroHealth = CreateSlider(canvasObject.transform, "Hero Health", new Vector2(300f, -76f), new Vector2(450f, 32f), new Color(0.14f, 0.88f, 1f));
            CreateText(canvasObject.transform, "光之战士", font, 28, Color.white, TextAnchor.MiddleLeft, new Vector2(300f, -37f), new Vector2(450f, 36f), new Vector2(0f, 1f));
            var monsterHealth = CreateSlider(canvasObject.transform, "Monster Health", new Vector2(-300f, -76f), new Vector2(450f, 32f), new Color(1f, 0.18f, 0.08f), new Vector2(1f, 1f));
            CreateText(canvasObject.transform, "岩角巨兽", font, 28, Color.white, TextAnchor.MiddleRight, new Vector2(-300f, -37f), new Vector2(450f, 36f), new Vector2(1f, 1f));
            var monsterStagger = CreateSlider(canvasObject.transform, "Monster Stagger", new Vector2(-300f, -116f), new Vector2(360f, 13f), new Color(1f, 0.72f, 0.12f), new Vector2(1f, 1f));
            var phaseLabel = CreateText(canvasObject.transform, "第一形态", font, 22, new Color(0.72f, 0.88f, 1f), TextAnchor.MiddleCenter, new Vector2(0f, -42f), new Vector2(520f, 34f), new Vector2(0.5f, 1f));

            var energy = CreateSlider(canvasObject.transform, "Hero Energy", Vector2.zero, new Vector2(360f, 20f), new Color(0.2f, 0.75f, 1f), new Vector2(0.5f, 0f));
            energy.GetComponent<RectTransform>().anchoredPosition = new Vector2(0f, 54f);
            CreateText(canvasObject.transform, "光能", font, 20, new Color(0.68f, 0.92f, 1f), TextAnchor.MiddleCenter, new Vector2(0f, 82f), new Vector2(180f, 28f), new Vector2(0.5f, 0f));

            var centerMessage = CreateText(canvasObject.transform, "", font, 62, Color.white, TextAnchor.MiddleCenter, Vector2.zero, new Vector2(1040f, 150f), new Vector2(0.5f, 0.62f));
            centerMessage.gameObject.SetActive(false);
            var comboLabel = CreateText(canvasObject.transform, "", font, 44, new Color(1f, 0.82f, 0.16f), TextAnchor.MiddleCenter, new Vector2(590f, 90f), new Vector2(280f, 80f), new Vector2(0.5f, 0.5f));
            comboLabel.gameObject.SetActive(false);

            var controls = CreateUiObject("Touch Controls", canvasObject.transform);
            StretchFullScreen(controls.GetComponent<RectTransform>());
            var joystickObject = CreateUiObject("Movement Joystick", controls.transform);
            var joystickRect = joystickObject.GetComponent<RectTransform>();
            SetRect(joystickRect, new Vector2(0f, 0f), new Vector2(0f, 0f), new Vector2(0.5f, 0.5f), new Vector2(205f, 205f), new Vector2(285f, 285f));
            var joystickImage = joystickObject.AddComponent<CircleGraphic>();
            joystickImage.color = new Color(0.08f, 0.35f, 0.62f, 0.46f);
            var handleObject = CreateUiObject("Handle", joystickObject.transform);
            var handleRect = handleObject.GetComponent<RectTransform>();
            SetRect(handleRect, new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), Vector2.zero, new Vector2(112f, 112f));
            var handleImage = handleObject.AddComponent<CircleGraphic>();
            handleImage.color = new Color(0.38f, 0.92f, 1f, 0.9f);
            handleImage.raycastTarget = false;
            var joystick = joystickObject.AddComponent<VirtualJoystick>();
            joystick.Configure(joystickRect, handleRect);

            var attackButton = CreateButton(controls.transform, "Attack", "✦", font, new Vector2(-172f, 168f), 188f, new Color(0.08f, 0.68f, 1f), new Vector2(1f, 0f));
            var dodgeButton = CreateButton(controls.transform, "Dodge", "↯", font, new Vector2(-390f, 118f), 148f, new Color(0.48f, 0.25f, 0.94f), new Vector2(1f, 0f));
            var jumpButton = CreateButton(controls.transform, "Jump", "↑", font, new Vector2(-320f, 330f), 142f, new Color(0.12f, 0.82f, 0.45f), new Vector2(1f, 0f));
            var skillButton = CreateButton(controls.transform, "Skill", "◎", font, new Vector2(-112f, 410f), 158f, new Color(1f, 0.34f, 0.06f), new Vector2(1f, 0f));

            var selection = CreateUiObject("Hero Selection", canvasObject.transform);
            StretchFullScreen(selection.GetComponent<RectTransform>());
            var overlay = selection.AddComponent<Image>();
            overlay.color = new Color(0.015f, 0.025f, 0.08f, 0.95f);
            CreateText(selection.transform, "选择光之战士", font, 54, Color.white, TextAnchor.MiddleCenter, new Vector2(0f, 330f), new Vector2(1200f, 90f));
            CreateText(selection.transform, "点击角色卡片", font, 28, new Color(0.62f, 0.83f, 1f), TextAnchor.MiddleCenter, new Vector2(0f, 260f), new Vector2(900f, 50f));
            var heroButtons = new Button[3];
            var cardColors = new[]
            {
                new Color(0.06f, 0.72f, 1f),
                new Color(0.12f, 0.35f, 0.95f),
                new Color(1f, 0.22f, 0.07f)
            };
            var cardNames = new[] { "极光\n均衡", "星驰\n速度", "烈阳\n力量" };
            for (var i = 0; i < heroButtons.Length; i++)
            {
                heroButtons[i] = CreateCardButton(selection.transform, cardNames[i], font, new Vector2((i - 1) * 420f, -10f), cardColors[i]);
            }

            var restart = CreateButton(canvasObject.transform, "Restart", "再战一次", font, new Vector2(0f, 120f), 210f, new Color(0.1f, 0.7f, 1f), new Vector2(0.5f, 0f), false);
            restart.GetComponent<RectTransform>().sizeDelta = new Vector2(360f, 96f);
            restart.gameObject.SetActive(false);

            var battleHud = canvasObject.AddComponent<BattleHud>();
            battleHud.Configure(heroHealth, monsterHealth, monsterStagger, energy, centerMessage, phaseLabel, comboLabel, damageOverlay, selection, controls, restart.gameObject, attackButton.targetGraphic, skillButton.targetGraphic);
            var uiMaterial = GetOrCreateUiMaterial();
            foreach (var graphic in canvasObject.GetComponentsInChildren<Graphic>(true))
            {
                graphic.material = uiMaterial;
            }
            return new HudBuildResult
            {
                Hud = battleHud,
                Joystick = joystick,
                AttackButton = attackButton,
                DodgeButton = dodgeButton,
                JumpButton = jumpButton,
                SkillButton = skillButton,
                RestartButton = restart,
                HeroButtons = heroButtons
            };
        }

        private static Button CreateCardButton(Transform parent, string label, Font font, Vector2 position, Color color)
        {
            var card = CreateUiObject(label.Replace("\n", " "), parent);
            var rect = card.GetComponent<RectTransform>();
            SetRect(rect, new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), position, new Vector2(330f, 430f));
            var image = card.AddComponent<Image>();
            image.color = new Color(color.r * 0.35f, color.g * 0.35f, color.b * 0.35f, 0.95f);
            var button = card.AddComponent<Button>();
            button.targetGraphic = image;
            var colors = button.colors;
            colors.normalColor = Color.white;
            colors.highlightedColor = Color.Lerp(Color.white, color, 0.22f);
            colors.pressedColor = Color.Lerp(Color.white, color, 0.52f);
            button.colors = colors;

            var emblem = CreateUiObject("Light Emblem", card.transform);
            var emblemRect = emblem.GetComponent<RectTransform>();
            SetRect(emblemRect, new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(0f, 72f), new Vector2(145f, 220f));
            var emblemImage = emblem.AddComponent<CircleGraphic>();
            emblemImage.color = Color.Lerp(new Color(0.72f, 0.78f, 0.86f), color, 0.38f);
            emblemImage.raycastTarget = false;

            var crest = CreateUiObject("Helmet Crest", emblem.transform);
            var crestRect = crest.GetComponent<RectTransform>();
            SetRect(crestRect, new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(0f, 78f), new Vector2(18f, 88f));
            var crestImage = crest.AddComponent<Image>();
            crestImage.color = color;
            crestImage.raycastTarget = false;

            for (var eyeIndex = 0; eyeIndex < 2; eyeIndex++)
            {
                var eye = CreateUiObject(eyeIndex == 0 ? "Left Light Eye" : "Right Light Eye", emblem.transform);
                var eyeRect = eye.GetComponent<RectTransform>();
                SetRect(eyeRect, new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(eyeIndex == 0 ? -38f : 38f, 30f), new Vector2(42f, 13f));
                eyeRect.localRotation = Quaternion.Euler(0f, 0f, eyeIndex == 0 ? -10f : 10f);
                var eyeImage = eye.AddComponent<Image>();
                eyeImage.color = new Color(0.72f, 1f, 1f);
                eyeImage.raycastTarget = false;
            }

            var core = CreateUiObject("Energy Core", emblem.transform);
            var coreRect = core.GetComponent<RectTransform>();
            SetRect(coreRect, new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(0f, -58f), new Vector2(34f, 34f));
            var coreImage = core.AddComponent<CircleGraphic>();
            coreImage.color = Color.Lerp(color, Color.white, 0.36f);
            coreImage.raycastTarget = false;
            CreateText(card.transform, label, font, 31, Color.white, TextAnchor.MiddleCenter, new Vector2(0f, -130f), new Vector2(290f, 100f));
            return button;
        }

        private static Slider CreateSlider(
            Transform parent,
            string name,
            Vector2 position,
            Vector2 size,
            Color fillColor,
            Vector2? anchor = null)
        {
            var anchorPoint = anchor ?? new Vector2(0f, 1f);
            var root = CreateUiObject(name, parent);
            var rect = root.GetComponent<RectTransform>();
            SetRect(rect, anchorPoint, anchorPoint, anchorPoint, position, size);
            var background = root.AddComponent<Image>();
            background.color = new Color(0.015f, 0.025f, 0.06f, 0.86f);

            var fillObject = CreateUiObject("Fill", root.transform);
            var fillRect = fillObject.GetComponent<RectTransform>();
            fillRect.anchorMin = Vector2.zero;
            fillRect.anchorMax = Vector2.one;
            fillRect.offsetMin = new Vector2(4f, 4f);
            fillRect.offsetMax = new Vector2(-4f, -4f);
            var fill = fillObject.AddComponent<Image>();
            fill.color = fillColor;

            var slider = root.AddComponent<Slider>();
            slider.transition = Selectable.Transition.None;
            slider.fillRect = fillRect;
            slider.minValue = 0f;
            slider.maxValue = 1f;
            slider.value = 1f;
            slider.interactable = false;
            return slider;
        }

        private static Button CreateButton(
            Transform parent,
            string name,
            string label,
            Font font,
            Vector2 position,
            float size,
            Color color,
            Vector2 anchor,
            bool circular = true)
        {
            var root = CreateUiObject(name, parent);
            var rect = root.GetComponent<RectTransform>();
            SetRect(rect, anchor, anchor, anchor, position, new Vector2(size, size));
            Graphic graphic;
            if (circular)
            {
                graphic = root.AddComponent<CircleGraphic>();
            }
            else
            {
                graphic = root.AddComponent<Image>();
            }
            graphic.color = new Color(color.r, color.g, color.b, 0.82f);
            var button = root.AddComponent<Button>();
            button.targetGraphic = graphic;
            var colors = button.colors;
            colors.normalColor = Color.white;
            colors.highlightedColor = new Color(1.15f, 1.15f, 1.15f, 1f);
            colors.pressedColor = new Color(0.65f, 0.72f, 0.82f, 1f);
            colors.fadeDuration = 0.06f;
            button.colors = colors;
            if (circular)
            {
                var glowObject = CreateUiObject("Inner action glow", root.transform);
                var glowRect = glowObject.GetComponent<RectTransform>();
                SetRect(glowRect, new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), Vector2.zero, Vector2.one * size * 0.66f);
                var glow = glowObject.AddComponent<CircleGraphic>();
                glow.color = new Color(0.015f, 0.035f, 0.09f, 0.42f);
                glow.raycastTarget = false;
            }
            CreateText(root.transform, label, font, circular ? 54 : 28, Color.white, TextAnchor.MiddleCenter, Vector2.zero, Vector2.zero).raycastTarget = false;
            return button;
        }

        private static Text CreateText(
            Transform parent,
            string value,
            Font font,
            int fontSize,
            Color color,
            TextAnchor alignment,
            Vector2 position,
            Vector2 size,
            Vector2? anchor = null)
        {
            var root = CreateUiObject("Text - " + (string.IsNullOrEmpty(value) ? "Message" : value.Replace("\n", " ")), parent);
            var rect = root.GetComponent<RectTransform>();
            var anchorPoint = anchor ?? new Vector2(0.5f, 0.5f);
            if (size == Vector2.zero)
            {
                rect.anchorMin = Vector2.zero;
                rect.anchorMax = Vector2.one;
                rect.offsetMin = Vector2.zero;
                rect.offsetMax = Vector2.zero;
            }
            else
            {
                SetRect(rect, anchorPoint, anchorPoint, anchorPoint, position, size);
            }
            var text = root.AddComponent<Text>();
            text.text = value;
            text.font = font;
            text.fontSize = fontSize;
            text.color = color;
            text.alignment = alignment;
            text.resizeTextForBestFit = false;
            text.horizontalOverflow = HorizontalWrapMode.Wrap;
            text.verticalOverflow = VerticalWrapMode.Overflow;
            text.raycastTarget = false;
            var outline = root.AddComponent<Outline>();
            outline.effectColor = new Color(0f, 0.02f, 0.08f, 0.82f);
            outline.effectDistance = new Vector2(2f, -2f);
            return text;
        }

        private static GameObject CreateUiObject(string name, Transform parent)
        {
            var gameObject = new GameObject(name, typeof(RectTransform));
            gameObject.transform.SetParent(parent, false);
            return gameObject;
        }

        private static void StretchFullScreen(RectTransform rect)
        {
            rect.anchorMin = Vector2.zero;
            rect.anchorMax = Vector2.one;
            rect.offsetMin = Vector2.zero;
            rect.offsetMax = Vector2.zero;
        }

        private static void SetRect(
            RectTransform rect,
            Vector2 anchorMin,
            Vector2 anchorMax,
            Vector2 pivot,
            Vector2 position,
            Vector2 size)
        {
            rect.anchorMin = anchorMin;
            rect.anchorMax = anchorMax;
            rect.pivot = pivot;
            rect.anchoredPosition = position;
            rect.sizeDelta = size;
        }

        private static Transform CreateLimbPivot(string name, Transform parent, Vector3 localPosition)
        {
            var pivot = new GameObject(name + " Pivot").transform;
            pivot.SetParent(parent, false);
            pivot.localPosition = localPosition;
            return pivot;
        }

        private static GameObject CreatePrimitive(
            string name,
            PrimitiveType primitiveType,
            Transform parent,
            Vector3 localPosition,
            Vector3 localScale,
            Material material,
            Vector3 localEuler = default,
            bool removeCollider = true)
        {
            var gameObject = GameObject.CreatePrimitive(primitiveType);
            gameObject.name = name;
            gameObject.transform.SetParent(parent, false);
            gameObject.transform.localPosition = localPosition;
            gameObject.transform.localRotation = Quaternion.Euler(localEuler);
            gameObject.transform.localScale = localScale;
            gameObject.GetComponent<Renderer>().sharedMaterial = material;
            if (removeCollider)
            {
                Object.DestroyImmediate(gameObject.GetComponent<Collider>());
            }
            return gameObject;
        }

        private static Material GetOrCreateMaterial(
            string name,
            Color color,
            float metallic,
            float smoothness,
            Color emission = default)
        {
            var path = $"{MaterialFolder}/{name}.mat";
            var material = AssetDatabase.LoadAssetAtPath<Material>(path);
            var shader = Shader.Find("MonsterPlanet/Stylized") ?? Shader.Find("Standard");
            if (material == null)
            {
                material = new Material(shader) { name = name };
                AssetDatabase.CreateAsset(material, path);
            }
            else if (material.shader != shader)
            {
                material.shader = shader;
            }

            if (material.HasProperty("_BaseColor")) material.SetColor("_BaseColor", color);
            if (material.HasProperty("_Color")) material.SetColor("_Color", color);
            if (material.HasProperty("_Metallic")) material.SetFloat("_Metallic", metallic);
            if (material.HasProperty("_Smoothness")) material.SetFloat("_Smoothness", smoothness);
            if (material.HasProperty("_Glossiness")) material.SetFloat("_Glossiness", smoothness);
            if (emission.maxColorComponent > 0f)
            {
                material.EnableKeyword("_EMISSION");
                if (material.HasProperty("_EmissionColor")) material.SetColor("_EmissionColor", emission);
            }
            else if (material.HasProperty("_EmissionColor"))
            {
                material.EnableKeyword("_EMISSION");
                material.SetColor("_EmissionColor", color * 0.22f);
            }
            EditorUtility.SetDirty(material);
            return material;
        }

        private static Material GetOrCreateUiMaterial()
        {
            var path = $"{MaterialFolder}/MonsterPlanetUI.mat";
            var shader = Shader.Find("UI/Default");
            if (shader == null)
            {
                throw new BuildFailedException("Unity UI/Default shader is unavailable.");
            }

            var material = AssetDatabase.LoadAssetAtPath<Material>(path);
            if (material == null)
            {
                material = new Material(shader) { name = "Monster Planet UI" };
                AssetDatabase.CreateAsset(material, path);
            }
            else
            {
                material.shader = shader;
            }
            EditorUtility.SetDirty(material);
            return material;
        }

        private static void EnsureFolder(string path)
        {
            if (AssetDatabase.IsValidFolder(path))
            {
                return;
            }

            var parent = Path.GetDirectoryName(path)?.Replace('\\', '/');
            var name = Path.GetFileName(path);
            if (!string.IsNullOrEmpty(parent)) EnsureFolder(parent);
            AssetDatabase.CreateFolder(parent ?? "Assets", name);
        }

        private struct MaterialPalette
        {
            public Material Arena;
            public Material ArenaEdge;
            public Material Rock;
            public Material Crystal;
            public Material Silver;
            public Material HeroBlue;
            public Material HeroDark;
            public Material HeroGlow;
            public Material Monster;
            public Material MonsterArmor;
            public Material MonsterGlow;
        }

        private struct HeroBuildResult
        {
            public HeroController Controller;
            public ProceduralHeroVisual Visual;
            public Transform AttackOrigin;
        }

        private struct MonsterBuildResult
        {
            public KaijuController Controller;
            public ProceduralKaijuVisual Visual;
        }

        private struct HudBuildResult
        {
            public BattleHud Hud;
            public VirtualJoystick Joystick;
            public Button AttackButton;
            public Button DodgeButton;
            public Button JumpButton;
            public Button SkillButton;
            public Button RestartButton;
            public Button[] HeroButtons;
        }
    }
}
#endif

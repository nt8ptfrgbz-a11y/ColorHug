#if UNITY_EDITOR
using System.IO;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.SceneManagement;

namespace MonsterPlanet3D.EditorTools
{
    [InitializeOnLoad]
    public static class PrototypeSceneAutoOpener
    {
        private const string ScenePath = "Assets/Scenes/MonsterPlanetPrototype.unity";

        static PrototypeSceneAutoOpener()
        {
            EditorApplication.delayCall += TryOpenPrototype;
            EditorApplication.playModeStateChanged += OnPlayModeStateChanged;
        }

        private static void OnPlayModeStateChanged(PlayModeStateChange state)
        {
            if (state == PlayModeStateChange.EnteredEditMode)
            {
                EditorApplication.delayCall += TryOpenPrototype;
            }
        }

        private static void TryOpenPrototype()
        {
            if (Application.isBatchMode || EditorApplication.isPlayingOrWillChangePlaymode)
            {
                return;
            }

            var activeScene = SceneManager.GetActiveScene();
            if (!string.IsNullOrEmpty(activeScene.path) || !File.Exists(ScenePath))
            {
                return;
            }

            EditorSceneManager.OpenScene(ScenePath, OpenSceneMode.Single);
            Debug.Log("Opened the playable Monster Planet scene automatically.");
        }
    }
}
#endif

using System.Collections.Generic;
using UnityEditor.Build;
using UnityEditor.Rendering;
using UnityEngine;
using UnityEngine.Rendering;

namespace MonsterPlanet3D.EditorTools
{
    /// <summary>
    /// Imported glTF materials are converted to the game's mobile stylized
    /// shader by PrototypeSceneBuilder. Their original Shader Graph variants
    /// are therefore unused and would otherwise add several minutes per build.
    /// </summary>
    public sealed class MonsterPlanetShaderStripper : IPreprocessShaders
    {
        public int callbackOrder => 0;

        public void OnProcessShader(
            Shader shader,
            ShaderSnippetData snippet,
            IList<ShaderCompilerData> data)
        {
            if (shader != null && shader.name.StartsWith("Shader Graphs/glTF"))
            {
                data.Clear();
            }
        }
    }
}

using UnityEngine;
using UnityEngine.UI;

namespace MonsterPlanet3D.UI
{
    [RequireComponent(typeof(CanvasRenderer))]
    public sealed class CircleGraphic : MaskableGraphic
    {
        [SerializeField, Range(12, 96)] private int segments = 48;

        protected override void OnPopulateMesh(VertexHelper vertexHelper)
        {
            vertexHelper.Clear();
            var rect = GetPixelAdjustedRect();
            var center = rect.center;
            var radius = Mathf.Min(rect.width, rect.height) * 0.5f;
            var vertex = UIVertex.simpleVert;
            vertex.color = color;
            vertex.position = center;
            vertex.uv0 = new Vector2(0.5f, 0.5f);
            vertexHelper.AddVert(vertex);

            for (var i = 0; i <= segments; i++)
            {
                var angle = i / (float)segments * Mathf.PI * 2f;
                var direction = new Vector2(Mathf.Cos(angle), Mathf.Sin(angle));
                vertex.position = center + direction * radius;
                vertex.uv0 = direction * 0.5f + Vector2.one * 0.5f;
                vertexHelper.AddVert(vertex);
            }

            for (var i = 0; i < segments; i++)
            {
                vertexHelper.AddTriangle(0, i + 1, i + 2);
            }
        }
    }
}

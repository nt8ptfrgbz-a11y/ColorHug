using UnityEngine;
using UnityEngine.EventSystems;

namespace MonsterPlanet3D.InputSystem
{
    public sealed class VirtualJoystick : MonoBehaviour, IPointerDownHandler, IDragHandler, IPointerUpHandler
    {
        [SerializeField] private RectTransform background;
        [SerializeField] private RectTransform handle;
        [SerializeField, Range(0.1f, 1f)] private float handleRange = 0.62f;
        [SerializeField] private float deadZone = 0.08f;

        public Vector2 Value { get; private set; }

        public void Configure(RectTransform joystickBackground, RectTransform joystickHandle)
        {
            background = joystickBackground;
            handle = joystickHandle;
        }

        public void OnPointerDown(PointerEventData eventData)
        {
            OnDrag(eventData);
        }

        public void OnDrag(PointerEventData eventData)
        {
            if (background == null || handle == null)
            {
                return;
            }

            if (!RectTransformUtility.ScreenPointToLocalPointInRectangle(
                    background,
                    eventData.position,
                    eventData.pressEventCamera,
                    out var localPoint))
            {
                return;
            }

            var radius = Mathf.Min(background.rect.width, background.rect.height) * 0.5f;
            if (radius <= 0f)
            {
                return;
            }

            var normalized = Vector2.ClampMagnitude(localPoint / radius, 1f);
            Value = normalized.magnitude < deadZone ? Vector2.zero : normalized;
            handle.anchoredPosition = normalized * radius * handleRange;
        }

        public void OnPointerUp(PointerEventData eventData)
        {
            Value = Vector2.zero;
            if (handle != null)
            {
                handle.anchoredPosition = Vector2.zero;
            }
        }
    }
}


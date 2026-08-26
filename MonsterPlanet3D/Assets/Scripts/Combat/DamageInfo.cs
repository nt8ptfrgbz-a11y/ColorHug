using UnityEngine;

namespace MonsterPlanet3D.Combat
{
    public readonly struct DamageInfo
    {
        public readonly GameObject Source;
        public readonly float Amount;
        public readonly Vector3 Point;
        public readonly Vector3 Direction;
        public readonly float Impulse;
        public readonly float HitStop;

        public DamageInfo(
            GameObject source,
            float amount,
            Vector3 point,
            Vector3 direction,
            float impulse = 0f,
            float hitStop = 0.035f)
        {
            Source = source;
            Amount = amount;
            Point = point;
            Direction = direction.sqrMagnitude > 0.001f ? direction.normalized : Vector3.forward;
            Impulse = impulse;
            HitStop = hitStop;
        }
    }

    public interface IImpulseReceiver
    {
        void ApplyImpulse(Vector3 direction, float strength);
    }
}


using System.Collections;
using UnityEngine;

namespace MonsterPlanet3D.Core
{
    public sealed class BattleTime : MonoBehaviour
    {
        private Coroutine _hitStopRoutine;
        private Coroutine _slowMotionRoutine;

        public void HitStop(float duration, float timeScale = 0.08f)
        {
            if (duration <= 0f)
            {
                return;
            }

            if (_hitStopRoutine != null)
            {
                StopCoroutine(_hitStopRoutine);
            }

            _hitStopRoutine = StartCoroutine(HitStopRoutine(duration, timeScale));
        }

        public void SlowMotion(float duration, float timeScale = 0.32f)
        {
            if (duration <= 0f)
            {
                return;
            }

            if (_slowMotionRoutine != null)
            {
                StopCoroutine(_slowMotionRoutine);
            }

            _slowMotionRoutine = StartCoroutine(SlowMotionRoutine(duration, timeScale));
        }

        private IEnumerator HitStopRoutine(float duration, float timeScale)
        {
            Time.timeScale = Mathf.Clamp(timeScale, 0.01f, 1f);
            yield return new WaitForSecondsRealtime(duration);
            Time.timeScale = 1f;
            _hitStopRoutine = null;
        }

        private IEnumerator SlowMotionRoutine(float duration, float timeScale)
        {
            Time.timeScale = Mathf.Clamp(timeScale, 0.05f, 1f);
            yield return new WaitForSecondsRealtime(duration);
            Time.timeScale = 1f;
            _slowMotionRoutine = null;
        }

        private void OnDisable()
        {
            Time.timeScale = 1f;
        }
    }
}

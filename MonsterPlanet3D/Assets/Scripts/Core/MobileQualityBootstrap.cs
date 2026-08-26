using UnityEngine;

namespace MonsterPlanet3D.Core
{
    public sealed class MobileQualityBootstrap : MonoBehaviour
    {
        [SerializeField] private int targetFrameRate = 60;

        private void Awake()
        {
            Application.targetFrameRate = targetFrameRate;
            QualitySettings.vSyncCount = 0;
            QualitySettings.shadowDistance = 32f;
            Screen.sleepTimeout = SleepTimeout.NeverSleep;
        }
    }
}

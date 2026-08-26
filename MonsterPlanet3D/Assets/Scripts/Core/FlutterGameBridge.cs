using System.Collections;
using UnityEngine;

namespace MonsterPlanet3D.Core
{
    public sealed class FlutterGameBridge : MonoBehaviour
    {
        [SerializeField] private BattleDirector director;
        private bool _subscribed;

        public void Configure(BattleDirector battleDirector)
        {
            director = battleDirector;
        }

        private void Start()
        {
            Subscribe();
            StartCoroutine(AnnounceReadyAfterSceneStart());
        }

        private IEnumerator AnnounceReadyAfterSceneStart()
        {
            yield return null;
            SendToFlutter.Send("{\"event\":\"ready\"}");
        }

        public void RestartBattle(string _)
        {
            director?.RestartBattle();
        }

        public void RequestExit(string _)
        {
            SendToFlutter.Send("{\"event\":\"exit\"}");
        }

        public void RequestExitFromButton()
        {
            RequestExit(string.Empty);
        }

        private void Subscribe()
        {
            if (_subscribed || director == null)
            {
                return;
            }

            director.BattleFinished += OnBattleFinished;
            _subscribed = true;
        }

        private void OnBattleFinished(bool heroWon)
        {
            SendToFlutter.Send(heroWon
                ? "{\"event\":\"battle_finished\",\"result\":\"win\"}"
                : "{\"event\":\"battle_finished\",\"result\":\"lose\"}");
        }

        private void OnDestroy()
        {
            if (_subscribed && director != null)
            {
                director.BattleFinished -= OnBattleFinished;
            }
        }
    }
}

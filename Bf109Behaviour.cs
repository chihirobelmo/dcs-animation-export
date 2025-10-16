using UnityEngine;
using System.Collections.Generic;
using System.IO;

public class Bf109Behaviour : MonoBehaviour
{
    [SerializeField]
    public string csvFilePath;
    private List<KeyframeData> keyframes = new();
    private float timeElapsed = 0f;

    [System.Serializable]
    public class KeyframeData
    {
        public float time;
        public Vector3 position;
        public Quaternion rotation;
    }

    void Start()
    {
        var lines = File.ReadAllLines(csvFilePath);
        for (int i = 1; i < lines.Length; i++)
        {
            var cols = lines[i].Split(',');
            keyframes.Add(new KeyframeData
            {
                time = float.Parse(cols[0]),
                position = new Vector3(float.Parse(cols[1]), float.Parse(cols[2]), float.Parse(cols[3])),
                rotation = Quaternion.Euler(
                    +float.Parse(cols[5]), // バンク角（ロール）X
                    +float.Parse(cols[6]), // 方位角（ヨー）Y
                    -float.Parse(cols[4])  // 仰角（ピッチ）Z  
                )
            });
        }
    }

    void Update()
    {
        timeElapsed += Time.deltaTime;
        // 時間に応じて2点間を補間
        for (int i = 0; i < keyframes.Count - 1; i++)
        {
            if (timeElapsed >= keyframes[i].time && timeElapsed < keyframes[i + 1].time)
            {
                float t = Mathf.InverseLerp(keyframes[i].time, keyframes[i + 1].time, timeElapsed);
                transform.position = Vector3.Lerp(keyframes[i].position, keyframes[i + 1].position, t) - keyframes[0].position;
                transform.rotation = Quaternion.Slerp(keyframes[i].rotation, keyframes[i + 1].rotation, t);
                break;
            }
        }
    }
}

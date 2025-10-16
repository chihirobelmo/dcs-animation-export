using UnityEngine;

public class AroundCamera : MonoBehaviour
{
    [SerializeField]
    public Transform target;      // 追従するターゲット
    public Vector3 offset = new Vector3(0, 5, -10); // ターゲットからの相対位置
    public float smoothSpeed = 100.0f; // 追従のスムーズさ

    void LateUpdate()
    {
        if (target == null) return;

        Vector3 desiredPosition = target.position + offset;
        Vector3 smoothedPosition = Vector3.Lerp(transform.position, desiredPosition, smoothSpeed);
        transform.position = smoothedPosition;

        transform.LookAt(target); // ターゲットを見る
    }
}

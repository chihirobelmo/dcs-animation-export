using UnityEngine;
using System.Collections.Generic;
using System.IO;

public class OriginReset : MonoBehaviour
{
    [SerializeField] public GameObject plane;
    [SerializeField] public List<GameObject> terrain;
    [SerializeField] public Camera camera;

    private const float WORLD_EDGE = 64f;

    private void LateUpdate()
    {
        CheckPlaneReachedWorldEdge(WORLD_EDGE);
    }

    private void CheckPlaneReachedWorldEdge(float worldEdge)
    {
        if (plane == null) return;

        // floating point origin reset
        if (plane.transform.position.x >= +worldEdge)
        {
            ResetFloatingPointOrigin(new Vector3(-worldEdge * 2.0f, 0, 0));
        }
        if (plane.transform.position.y >= +worldEdge)
        {
            ResetFloatingPointOrigin(new Vector3(0, -worldEdge * 2.0f, 0));
        }
        if (plane.transform.position.z >= +worldEdge)
        {
            ResetFloatingPointOrigin(new Vector3(0, 0, -worldEdge * 2.0f));
        }
        if (plane.transform.position.x <= -worldEdge)
        {
            ResetFloatingPointOrigin(new Vector3(+worldEdge * 2.0f, 0, 0));
        }
        if (plane.transform.position.z <= -worldEdge)
        {
            ResetFloatingPointOrigin(new Vector3(0, +worldEdge * 2.0f, 0));
        }
        if (plane.transform.position.z <= -worldEdge)
        {
            ResetFloatingPointOrigin(new Vector3(0, 0, +worldEdge * 2.0f));
        }
    }

    /// <summary>
    /// Reset the floating point origin
    /// </summary>
    private void ResetFloatingPointOrigin(Vector3 offsetForReset)
    {
        /*
         Q: How do games like KSP overcome the floating point precision limit

         https://www.reddit.com/r/Unity3D/comments/nozmk6/how_do_games_like_ksp_overcome_the_floating_point/

         They held a talk at Unite 2013. It's quite old, but I don't think the implementation has changed.
         TLDR; They use a technique called floating origin.
         They store the position of objects internally in double precision,
         but the transforms are not necessarily at the same position.
         When the player has moved a specific distance (like 1km) they move everything back 1km.
         This way the player is now at the world origin again. They do this for everything.
         */

        // revert everything to origin
        plane.transform.position += offsetForReset;
        camera.transform.position += offsetForReset;
        terrain.ForEach(t => t.transform.position += offsetForReset);
    }
}

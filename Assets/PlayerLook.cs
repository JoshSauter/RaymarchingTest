using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PlayerLook : MonoBehaviour {
	public bool DEBUG = false;
    Transform playerTransform;
    public Transform cameraTransform;
	Vector3 cameraInitialLocalPos;
	[Range(0.01f,1)]
	public float generalSensitivity = 0.5f;
	[Range(0.01f,1)]
	public float sensitivityX = 0.5f;
	[Range(0.01f,1)]
	public float sensitivityY = 0.5f;
    public float rotationY = 0F;
	private float yClamp = 85;

	private const int lookAmountMultiplier = 14;

	public float outsideMultiplier = 1f;

	/// <summary>
	/// Returns the rotationY normalized to the range (-1, 1)
	/// </summary>
	public float normalizedY {
		get {
			return rotationY / yClamp;
		}
	}

    // Use this for initialization
    void Start () {

        playerTransform = gameObject.transform;
        cameraTransform = playerTransform.GetChild(0);
		cameraInitialLocalPos = cameraTransform.localPosition;

		//print(cameraTransform.rotation.x + ", " + cameraTransform.rotation.y + ", " + cameraTransform.rotation.z + ", " + cameraTransform.rotation.w);
		//print(cameraTransform.position.x + ", " + cameraTransform.position.y + ", " + cameraTransform.position.z);

		if (!Application.isEditor) {
			Cursor.lockState = CursorLockMode.Locked;
			Cursor.visible = false;
		}
	}

	void Update() {
        Vector2 rightStick = Input.GetAxis("Mouse X") * Vector2.right + Input.GetAxis("Mouse Y") * Vector2.up;
		Look(rightStick);

		if (Input.GetKey(KeyCode.LeftControl) && Input.GetKeyDown(KeyCode.L)) {
			Cursor.lockState = (Cursor.lockState != CursorLockMode.Locked) ? CursorLockMode.Locked : CursorLockMode.None;
			Cursor.visible = !Cursor.visible;
		}
	}

	private void Look(Vector2 lookDirection) {
		LookHorizontal(lookDirection.x * lookAmountMultiplier * generalSensitivity * sensitivityX * outsideMultiplier);
		rotationY += lookDirection.y * lookAmountMultiplier * generalSensitivity * sensitivityY * outsideMultiplier;
		rotationY = Mathf.Clamp(rotationY, -yClamp, yClamp);
		LookVertical(rotationY);
	}

    private void LookVertical(float rotation) {
        cameraTransform.localEulerAngles = new Vector3(-rotation, cameraTransform.localEulerAngles.y, cameraTransform.localEulerAngles.z);
    }

    private void LookHorizontal(float rotation) {
        playerTransform.Rotate(new Vector3(0, rotation, 0));
    }

	private void OnApplicationFocus(bool focus) {
#if !UNITY_EDITOR
		Cursor.lockState = focus ? CursorLockMode.Locked : CursorLockMode.None;
		Cursor.visible = !focus;
#endif
	}
}

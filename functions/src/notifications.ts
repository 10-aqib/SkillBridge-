import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

export const onNotificationCreated = functions.firestore
  .document("notifications/{notificationId}")
  .onCreate(async (snap, context) => {
    const data = snap.data();
    if (!data) return null;

    const { userId, title, body, payload } = data;

    if (!userId || !title || !body) {
      console.log("Missing required notification fields", data);
      return null;
    }

    try {
      const userDoc = await admin.firestore().collection("users").doc(userId).get();
      if (!userDoc.exists) {
        console.log("User not found:", userId);
        return null;
      }

      const userData = userDoc.data();
      const fcmToken = userData?.fcmToken;

      if (!fcmToken) {
        console.log("User does not have an FCM token:", userId);
        return null;
      }

      const message: admin.messaging.Message = {
        token: fcmToken,
        notification: {
          title: title,
          body: body,
        },
        data: payload || {},
      };

      const response = await admin.messaging().send(message);
      console.log("Successfully sent message:", response);
      return null;
    } catch (error) {
      console.error("Error sending notification:", error);
      return null;
    }
  });

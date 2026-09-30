import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

// Example function to assign custom claims when a user registers
export const onUserCreated = functions.auth.user().onCreate(async (user) => {
    // By default, assigning client role unless handled differently
    const customClaims = {
        role: "client"
    };

    try {
        await admin.auth().setCustomUserClaims(user.uid, customClaims);
        // Sync role to Firestore
        await admin.firestore().collection("users").doc(user.uid).set({
            uid: user.uid,
            email: user.email,
            role: "client",
            createdAt: admin.firestore.FieldValue.serverTimestamp()
        }, { merge: true });
        
        console.log(`Custom claims set for user ${user.uid}`);
    } catch (error) {
        console.error("Error setting custom claims:", error);
    }
});

import * as admin from "firebase-admin";
import { onDocumentCreated } from "firebase-functions/v2/firestore";

/** Keeps public rating totals derived from completed-contract reviews. */
export const aggregateReviewRating = onDocumentCreated(
  "reviews/{reviewId}",
  async (event) => {
    const review = event.data?.data();
    const revieweeId = review?.revieweeId;
    if (typeof revieweeId !== "string" || revieweeId.length === 0) return;

    const db = admin.firestore();
    const reviews = await db
      .collection("reviews")
      .where("revieweeId", "==", revieweeId)
      .get();
    if (reviews.empty) return;

    const totalRating = reviews.docs.reduce((sum, doc) => {
      const rating = doc.data().rating;
      return sum + (typeof rating === "number" ? rating : 0);
    }, 0);
    const rating = Math.round((totalRating / reviews.size) * 10) / 10;
    const update: Record<string, number> = {
      rating,
      totalReviews: reviews.size,
    };
    const userRef = db.collection("users").doc(revieweeId);
    const user = await userRef.get();
    if (user.data()?.workerProfile) {
      update["workerProfile.averageRating"] = rating;
      update["workerProfile.totalReviews"] = reviews.size;
    }
    await userRef.update(update);
  },
);

"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.aggregateReviewRating = void 0;
const admin = require("firebase-admin");
const firestore_1 = require("firebase-functions/v2/firestore");
/** Keeps public rating totals derived from completed-contract reviews. */
exports.aggregateReviewRating = (0, firestore_1.onDocumentCreated)("reviews/{reviewId}", async (event) => {
    var _a, _b;
    const review = (_a = event.data) === null || _a === void 0 ? void 0 : _a.data();
    const revieweeId = review === null || review === void 0 ? void 0 : review.revieweeId;
    if (typeof revieweeId !== "string" || revieweeId.length === 0)
        return;
    const db = admin.firestore();
    const reviews = await db
        .collection("reviews")
        .where("revieweeId", "==", revieweeId)
        .get();
    if (reviews.empty)
        return;
    const totalRating = reviews.docs.reduce((sum, doc) => {
        const rating = doc.data().rating;
        return sum + (typeof rating === "number" ? rating : 0);
    }, 0);
    const rating = Math.round((totalRating / reviews.size) * 10) / 10;
    const update = {
        rating,
        totalReviews: reviews.size,
    };
    const userRef = db.collection("users").doc(revieweeId);
    const user = await userRef.get();
    if ((_b = user.data()) === null || _b === void 0 ? void 0 : _b.workerProfile) {
        update["workerProfile.averageRating"] = rating;
        update["workerProfile.totalReviews"] = reviews.size;
    }
    await userRef.update(update);
});
//# sourceMappingURL=reviews.js.map
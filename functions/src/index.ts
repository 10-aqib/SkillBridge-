
import * as admin from "firebase-admin";

admin.initializeApp();

// Export all functions
export * from "./auth";
export * from "./notifications";
export * from "./reviews";
export * from "./proposals";
export * from "./profiles";
export * from "./contracts";
export * from "./chats";

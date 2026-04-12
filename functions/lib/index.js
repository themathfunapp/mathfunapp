"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.onFamilyRemoteDuelInviteCreated = exports.verifyPinResetCode = exports.requestPinResetCode = void 0;
const functions = require("firebase-functions/v1");
const admin = require("firebase-admin");
admin.initializeApp();
const CODE_EXPIRY_MINUTES = 10;
const CODE_LENGTH = 6;
/**
 * 6 haneli rastgele kod üretir
 */
function generateCode() {
    let code = "";
    for (let i = 0; i < CODE_LENGTH; i++) {
        code += Math.floor(Math.random() * 10).toString();
    }
    return code;
}
/**
 * E-posta adresine PIN sıfırlama kodu gönderir.
 * Firebase "Trigger Email from Firestore" extension kurulu olmalı.
 * Extension: https://firebase.google.com/products/extensions/firestore-send-email
 */
exports.requestPinResetCode = functions.https.onCall(async (data, context) => {
    var _a, _b;
    if (!(context === null || context === void 0 ? void 0 : context.auth)) {
        throw new functions.https.HttpsError("unauthenticated", "Oturum açmanız gerekiyor.");
    }
    const uid = context.auth.uid;
    let email = (_a = context.auth.token) === null || _a === void 0 ? void 0 : _a.email;
    if (!email) {
        const userDoc = await admin.firestore().collection("users").doc(uid).get();
        email = (_b = userDoc.data()) === null || _b === void 0 ? void 0 : _b.email;
    }
    if (!email || typeof email !== "string") {
        throw new functions.https.HttpsError("failed-precondition", "E-posta adresi bulunamadı. Lütfen e-posta ile giriş yapın.");
    }
    const db = admin.firestore();
    const code = generateCode();
    const expiresAt = new Date(Date.now() + CODE_EXPIRY_MINUTES * 60 * 1000);
    try {
        await db.runTransaction(async (tx) => {
            const codeRef = db.collection("pinResetCodes").doc(uid);
            tx.set(codeRef, {
                code,
                email,
                expiresAt: admin.firestore.Timestamp.fromDate(expiresAt),
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
            });
            const mailRef = db.collection("mail").doc();
            tx.set(mailRef, {
                to: email,
                message: {
                    subject: "MathFun - PIN Sıfırlama Kodu",
                    text: `PIN sıfırlama kodunuz: ${code}\n\nBu kod ${CODE_EXPIRY_MINUTES} dakika geçerlidir.\n\nEğer bu talebi siz yapmadıysanız, bu e-postayı görmezden gelebilirsiniz.`,
                    html: `
            <div style="font-family: Arial, sans-serif; max-width: 400px; margin: 0 auto;">
              <h2 style="color: #2C3E50;">MathFun - PIN Sıfırlama</h2>
              <p>PIN sıfırlama kodunuz:</p>
              <p style="font-size: 24px; font-weight: bold; letter-spacing: 4px; color: #3498db;">${code}</p>
              <p style="color: #7f8c8d; font-size: 12px;">Bu kod ${CODE_EXPIRY_MINUTES} dakika geçerlidir.</p>
              <p style="color: #7f8c8d; font-size: 12px;">Eğer bu talebi siz yapmadıysanız, bu e-postayı görmezden gelebilirsiniz.</p>
            </div>
          `,
                },
            });
        });
    }
    catch (err) {
        functions.logger.error("requestPinResetCode error", err);
        throw new functions.https.HttpsError("internal", "Kod gönderilirken hata oluştu. Lütfen tekrar deneyin.");
    }
    return { success: true, message: "Kod e-posta adresinize gönderildi." };
});
/**
 * Girilen kodu doğrular. Başarılı ise PIN sıfırlamaya izin verilir.
 */
exports.verifyPinResetCode = functions.https.onCall(async (data, context) => {
    if (!(context === null || context === void 0 ? void 0 : context.auth)) {
        throw new functions.https.HttpsError("unauthenticated", "Oturum açmanız gerekiyor.");
    }
    const uid = context.auth.uid;
    const code = data === null || data === void 0 ? void 0 : data.code;
    if (!code || typeof code !== "string" || code.length !== CODE_LENGTH) {
        throw new functions.https.HttpsError("invalid-argument", "Geçerli bir 6 haneli kod girin.");
    }
    const db = admin.firestore();
    const codeRef = db.collection("pinResetCodes").doc(uid);
    const doc = await codeRef.get();
    if (!doc.exists) {
        throw new functions.https.HttpsError("not-found", "Kod bulunamadı veya süresi dolmuş. Lütfen yeni kod isteyin.");
    }
    const { code: storedCode, expiresAt } = doc.data();
    const expiry = expiresAt.toDate();
    if (new Date() > expiry) {
        await codeRef.delete();
        throw new functions.https.HttpsError("failed-precondition", "Kodun süresi dolmuş. Lütfen yeni kod isteyin.");
    }
    if (storedCode !== code.trim()) {
        throw new functions.https.HttpsError("invalid-argument", "Yanlış kod. Lütfen tekrar deneyin.");
    }
    await codeRef.delete();
    return { success: true, message: "Kod doğrulandı." };
});
/**
 * Uzaktan aile düellosu: davet oluşunca çocuğa FCM bildirimi.
 * Jeton: users/{toUid}/private/fcm/current (Flutter PushNotificationService).
 */
exports.onFamilyRemoteDuelInviteCreated = functions.firestore
    .document("familyRemoteDuelInvites/{inviteId}")
    .onCreate(async (snap, context) => {
    var _a;
    const d = snap.data();
    if (!d || d.status !== "pending") {
        return;
    }
    const toUid = d.toUserId;
    const fromName = d.fromDisplayName || "Ailen";
    const sessionId = d.sessionId || "";
    if (!toUid) {
        return;
    }
    const tokenSnap = await admin
        .firestore()
        .doc(`users/${toUid}/private/fcm/current`)
        .get();
    const token = (_a = tokenSnap.data()) === null || _a === void 0 ? void 0 : _a.token;
    if (!token) {
        functions.logger.info("onFamilyRemoteDuelInviteCreated: no FCM token", {
            toUid,
        });
        return;
    }
    try {
        await admin.messaging().send({
            token,
            notification: {
                title: "MathFun — Aile düellosu",
                body: `${fromName} seni uzaktan düelloya davet etti.`,
            },
            data: {
                type: "family_remote_duel_invite",
                inviteId: context.params.inviteId,
                sessionId,
            },
        });
    }
    catch (err) {
        functions.logger.error("onFamilyRemoteDuelInviteCreated FCM error", err);
    }
});
//# sourceMappingURL=index.js.map
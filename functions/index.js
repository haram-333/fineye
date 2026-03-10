const functions = require('firebase-functions');
const admin = require('firebase-admin');

// Initialize Firebase Admin SDK
admin.initializeApp();

/**
 * Cloud Function to send push notifications when a new notification is created in Firestore
 * 
 * Listens to: user_notifications/{userId}/notifications/{notificationId}
 * Sends FCM push notification to the user's device
 */
exports.sendPushNotificationOnNotificationCreate = functions.firestore
  .document('user_notifications/{userId}/notifications/{notificationId}')
  .onCreate(async (snap, context) => {
    const notificationData = snap.data();
    const userId = context.params.userId;
    const notificationId = context.params.notificationId;

    console.log(`📬 New notification created: ${notificationId} for user: ${userId}`);
    console.log('Notification data:', JSON.stringify(notificationData, null, 2));

    // Skip if notification is suppressed
    if (notificationData.suppressed === true) {
      console.log('🔇 Notification is suppressed, skipping push notification');
      return null;
    }

    // Skip if notification is already read (shouldn't happen on create, but safety check)
    if (notificationData.isRead === true) {
      console.log('⚠️ Notification is already read, skipping push notification');
      return null;
    }

    try {
      // Get user's FCM token(s) from Firestore
      const fcmTokenDoc = await admin.firestore()
        .collection('user_fcm_tokens')
        .doc(userId)
        .get();

      if (!fcmTokenDoc.exists) {
        console.log(`⚠️ No FCM token found for user: ${userId}`);
        return null;
      }

      const tokenData = fcmTokenDoc.data();
      const fcmToken = tokenData?.token;

      if (!fcmToken) {
        console.log(`⚠️ FCM token is empty for user: ${userId}`);
        return null;
      }

      console.log(`📱 Sending push notification to token: ${fcmToken.substring(0, 20)}...`);

      // Prepare notification title and body
      // For now, we'll use the translation keys and let the app translate
      // In production, you might want to translate on the server based on user's language preference
      const titleKey = notificationData.titleKey || 'notifications_title';
      const messageKey = notificationData.messageKey || 'notifications_message';
      const titleParams = notificationData.titleParams || {};
      const messageParams = notificationData.messageParams || {};

      // Default English translations (app will translate based on user's language)
      const defaultTitle = getDefaultTranslation(titleKey, titleParams);
      const defaultBody = getDefaultTranslation(messageKey, messageParams);

      // Build the notification payload
      const message = {
        token: fcmToken,
        notification: {
          title: defaultTitle,
          body: defaultBody,
        },
        data: {
          type: notificationData.type || 'system',
          notificationId: notificationId,
          userId: userId,
          titleKey: titleKey,
          messageKey: messageKey,
          titleParams: JSON.stringify(titleParams),
          messageParams: JSON.stringify(messageParams),
          isCritical: String(notificationData.isCritical || false),
        },
        android: {
          priority: 'high',
          notification: {
            sound: 'default',
            channelId: 'fineye_notifications',
            priority: notificationData.isCritical ? 'high' : 'default',
          },
        },
        apns: {
          payload: {
            aps: {
              sound: 'default',
              badge: 1,
              priority: notificationData.isCritical ? 10 : 5,
            },
          },
        },
      };

      // Send the push notification
      const response = await admin.messaging().send(message);
      console.log(`✅ Successfully sent push notification: ${response}`);
      
      return { success: true, messageId: response };
    } catch (error) {
      console.error(`❌ Error sending push notification:`, error);
      console.error(`Error details:`, {
        userId,
        notificationId,
        errorMessage: error.message,
        errorStack: error.stack,
      });
      
      // Don't throw error - we don't want to fail the notification creation
      // The notification is already saved in Firestore, so user can see it in the app
      return null;
    }
  });

/**
 * Get default English translation for a translation key
 * This is a fallback - the app will translate based on user's language
 */
function getDefaultTranslation(key, params = {}) {
  // Common translations (English defaults)
  const translations = {
    'notif_invoice_created': 'New Invoice Created',
    'notif_invoice_created_msg': 'Invoice @invoiceNumber from @supplierName has been created successfully',
    'notif_invoice_uploaded': 'Invoice Uploaded Successfully',
    'notif_invoice_processed': 'Invoice Processed',
    'notif_invoice_error': 'Invoice Processing Error',
    'notif_invoice_missing_data': 'Invoice Has Missing Data',
    'notif_invoice_high_risk': 'High-Risk Invoice Detected',
    'notif_invoice_needs_review': 'Invoice Needs Your Review',
    'notif_invoice_approved': 'Invoice Approved',
    'notif_invoice_rejected': 'Invoice Rejected',
    'notif_invoice_duplicate': 'Duplicate Invoice Detected',
    'notif_vat_return_due': 'VAT Return Due in @days days',
    'notif_vat_return_due_today': 'VAT Return Due Today',
    'notif_vat_payment_due': 'VAT Payment Due',
    'notif_ct_return_due': 'Corporate Tax Return Due in @days days',
    'notif_ct_return_due_today': 'Corporate Tax Return Due Today',
    'notif_compliance_status_changed': 'Compliance Status Changed',
    'notif_compliance_ready': 'Ready to File – All Checks Passed',
    'notif_compliance_action_needed': 'Action Needed – Review Alerts',
    'notifications_title': 'Notification',
    'notifications_message': 'You have a new notification',
  };

  let translation = translations[key] || key;

  // Replace parameters in translation using the same format as Flutter GetX trParams (@paramName)
  if (params && Object.keys(params).length > 0) {
    Object.keys(params).forEach(paramKey => {
      const placeholder = `@${paramKey}`;
      translation = translation.replace(new RegExp(placeholder, 'g'), params[paramKey] || '');
    });
  }

  return translation;
}

/**
 * Callable function to grant/revoke admin access using Firebase custom claims.
 * Only existing admins can call this function.
 *
 * Payload:
 * {
 *   email: string,
 *   makeAdmin: boolean
 * }
 */
exports.setAdminClaim = functions.https.onCall(async (data, context) => {
  if (!context.auth || context.auth.token.admin !== true) {
    throw new functions.https.HttpsError(
      'permission-denied',
      'Only admins can manage admin access.'
    );
  }

  const email = (data.email || '').toString().trim().toLowerCase();
  const makeAdmin = data.makeAdmin === true;

  if (!email) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'email is required.'
    );
  }

  try {
    const userRecord = await admin.auth().getUserByEmail(email);
    const existingClaims = userRecord.customClaims || {};

    await admin.auth().setCustomUserClaims(userRecord.uid, {
      ...existingClaims,
      admin: makeAdmin,
    });

    return {
      success: true,
      uid: userRecord.uid,
      email: userRecord.email,
      admin: makeAdmin,
      message: makeAdmin ? 'Admin access granted.' : 'Admin access revoked.',
    };
  } catch (error) {
    console.error('setAdminClaim error:', error);
    throw new functions.https.HttpsError(
      'internal',
      'Failed to update admin claim.'
    );
  }
});


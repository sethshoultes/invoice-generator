/**
 * Cloud Functions entry point
 *
 * This file will be the main entry point for all Cloud Functions.
 * API routes will be added in subsequent phases.
 */

import * as functions from 'firebase-functions'

/**
 * Hello World function for testing deployment
 */
export const helloWorld = functions.https.onRequest((request, response) => {
  response.json({
    message: 'Invoice Digitization Service - Cloud Functions are running!',
    version: '1.0.0',
    timestamp: new Date().toISOString(),
  })
})

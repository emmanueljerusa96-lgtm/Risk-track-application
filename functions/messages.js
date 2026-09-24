'use strict';

// Never include a report's content, location, reporter or email in push alerts:
// system notifications can be displayed on a locked screen.
function reviewMessage(before, after) {
  if (before.verificationStatus !== after.verificationStatus) {
    if (after.verificationStatus === 'verified') {
      return { kind: 'report_verified', title: 'Report verified',
        body: 'An administrator verified a community report you submitted.' };
    }
    if (after.verificationStatus === 'rejected') {
      return { kind: 'report_rejected', title: 'Report review updated',
        body: 'An administrator reviewed a community report you submitted.' };
    }
    return { kind: 'report_review', title: 'Report review updated',
      body: 'The review of a community report you submitted has changed.' };
  }
  if (before.status !== after.status && after.status === 'resolved') {
    return { kind: 'report_resolved', title: 'Report marked resolved',
      body: 'A community report you submitted was marked resolved.' };
  }
  if (before.status !== after.status) {
    return { kind: 'report_status', title: 'Report status updated',
      body: 'The status of a community report you submitted has changed.' };
  }
  return null;
}

module.exports = { reviewMessage };

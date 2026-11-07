/* Next Eleven opponent-review UI adapter. Loaded by application Settings page.
 * All reads use existing authenticated Sync transport; server enforces RLS.
 * No direct mutation of opponents or historical fixtures is permitted here.
 */
(function (root) {
  'use strict';
  const escapeHtml = value => String(value == null ? '' : value).replace(/[&<>"']/g, ch => ({
    '&':'&amp;', '<':'&lt;', '>':'&gt;', '"':'&quot;', "'":'&#39;'
  })[ch]);
  function createOpponentReviewInbox(deps) {
    const {request, userId, isAdmin, notify, confirm, refresh} = deps;
    if (typeof request !== 'function' || typeof userId !== 'function')
      throw new TypeError('Authenticated request and userId are required');
    async function load() {
      const uid=userId();
      if (!uid) throw new Error('Authentication required');
      const notifications=await request('GET','opponent_review_notifications',null,{
        select:'id,request_id,request_kind,event_type,message,created_at,read_at',
        recipient_id:'eq.'+uid,order:'created_at.desc',limit:'100'
      });
      if (!Array.isArray(notifications)) throw new Error('Notification response must be an array');
      return notifications;
    }
    function render(rows) {
      if (!Array.isArray(rows)) throw new TypeError('Notifications must be an array');
      if (!rows.length) return '<p class="muted">No opponent review notifications.</p>';
      return '<ul class="opponent-review-inbox">'+rows.map(row=>
        '<li data-notification-id="'+escapeHtml(row.id)+'" class="'+(row.read_at?'read':'unread')+'">'+
        '<span>'+escapeHtml(row.message)+'</span> '+
        '<small>'+escapeHtml(row.event_type)+'</small>'+
        (!row.read_at?'<button type="button" data-mark-read="'+escapeHtml(row.id)+'">Mark read</button>':'')+
        '</li>'
      ).join('')+'</ul>';
    }
    async function markRead(notificationId) {
      const uid=userId();
      if (!uid) throw new Error('Authentication required');
      if (!notificationId) throw new Error('Notification id required');
      await request('PATCH','opponent_review_notifications',{read_at:new Date().toISOString()},
        {id:'eq.'+notificationId,recipient_id:'eq.'+uid,read_at:'is.null'});
      if (typeof refresh==='function') await refresh();
    }
    async function completeDeletion(requestId) {
      if (!userId() || !isAdmin()) throw new Error('Administrator authorization required');
      if (!requestId) throw new Error('Approved deletion request id required');
      if (typeof confirm==='function' && !await confirm('Complete approved opponent deletion? Historical fixtures will remain unchanged.'))
        return false;
      const result=await request('POST','rpc/complete_approved_opponent_deletion',{p_request_id:requestId});
      if (result !== true) throw new Error('Deletion completion was not confirmed by the server');
      if (typeof notify==='function') notify('Approved deletion completed.');
      if (typeof refresh==='function') await refresh();
      return true;
    }
    return Object.freeze({load,render,markRead,completeDeletion});
  }
  root.Next11OpponentReview=createOpponentReviewInbox;
  if (typeof module!=='undefined' && module.exports) module.exports=createOpponentReviewInbox;
})(typeof globalThis!=='undefined'?globalThis:this);

const assert=require('node:assert/strict');
const create=require('../js/opponent-review-inbox.js');
(async()=>{
 const calls=[],messages=[];
 let admin=false,approved=true,refreshes=0;
 const api=create({
  userId:()=> '00000000-0000-0000-0000-00000000a002',
  isAdmin:()=>admin, confirm:async()=>approved,
  request:async(...args)=>{calls.push(args);return args[0]==='GET'?[{id:'n1',message:'<script>alert(1)</script>',event_type:'decided',read_at:null}]:args[1]==='rpc/complete_approved_opponent_deletion'?true:[]},
  notify:x=>messages.push(x),refresh:async()=>{refreshes++}
 });
 const rows=await api.load();
 assert.equal(calls[0][1],'opponent_review_notifications');
 assert.equal(calls[0][3].recipient_id,'eq.00000000-0000-0000-0000-00000000a002');
 assert(!api.render(rows).includes('<script>'),'Notification message must be HTML escaped');
 assert(api.render(rows).includes('&lt;script&gt;'));
 await api.markRead('n1');
 assert.equal(calls[1][0],'PATCH');
 assert.equal(calls[1][3].recipient_id,'eq.00000000-0000-0000-0000-00000000a002');
 await assert.rejects(()=>api.completeDeletion('req1'),/Administrator/);
 assert(!calls.some(x=>x[1].startsWith('rpc/')),'Non-admin must not invoke completion RPC');
 admin=true;approved=false;
 assert.equal(await api.completeDeletion('req1'),false);
 assert(!calls.some(x=>x[1].startsWith('rpc/')),'Cancelled deletion must not invoke RPC');
 approved=true;
 assert.equal(await api.completeDeletion('req1'),true);
 assert.equal(calls.at(-1)[1],'rpc/complete_approved_opponent_deletion');
 assert.deepEqual(calls.at(-1)[2],{p_request_id:'req1'});
 assert.equal(refreshes,2);
 assert.equal(messages.length,1);
 assert(!calls.some(x=>x[1]==='opponents'),'UI must not directly mutate opponents');
 const failedApi=create({userId:()=> 'user-a',isAdmin:()=>true,confirm:async()=>true,request:async()=>false,notify:()=>{throw Error('must not notify')},refresh:async()=>{throw Error('must not refresh')}});
 await assert.rejects(()=>failedApi.completeDeletion('req-false'),/not confirmed/);
 // Malformed server responses must not masquerade as an empty inbox.
 const malformed=create({userId:()=> 'user-a',isAdmin:()=>false,request:async()=>({error:'upstream failure'})});
 await assert.rejects(()=>malformed.load(),/Notification response must be an array/);
 // A changing identity callback must not redirect the mark-read request to another owner.
 let identityCalls=0;
 const changing=create({userId:()=> (++identityCalls===1?'user-a':'user-b'),isAdmin:()=>false,
  request:async(...args)=>{assert.equal(args[3].recipient_id,'eq.user-a');return []}});
 await changing.markRead('n1');
 assert.equal(identityCalls,1,'Mark-read should resolve the authenticated identity once');
 // A user switch or revoked admin role during the confirmation dialog must block the RPC.
 for (const change of ['user','role']) {
  let currentUser='user-a', currentAdmin=true, rpcCalls=0;
  const guarded=create({userId:()=>currentUser,isAdmin:()=>currentAdmin,
   confirm:async()=>{if(change==='user')currentUser='user-b';else currentAdmin=false;return true},
   request:async()=>{rpcCalls++;return true}});
  await assert.rejects(()=>guarded.completeDeletion('req-switch'),/authorization changed/);
  assert.equal(rpcCalls,0,'No completion RPC after '+change+' changes');
 }
 console.log('PASS: inbox RLS query, escaping, read state, admin gate, cancel, approved RPC, no direct opponent mutation');
})().catch(e=>{console.error(e);process.exitCode=1});

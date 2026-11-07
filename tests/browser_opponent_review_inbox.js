// Browser acceptance of the standalone opponent review inbox adapter.
// Mocked authenticated transport, never contacts production or Supabase.
const {chromium}=require('playwright');
const fs=require('node:fs');
const path=require('node:path');
const assert=require('node:assert/strict');
const source=fs.readFileSync(path.join(__dirname,'..','js','opponent-review-inbox.js'),'utf8');
(async()=>{
 const browser=await chromium.launch({headless:true});
 try {
  const page=await browser.newPage();
  await page.setContent('<section id="inbox"></section>');
  await page.evaluate(()=>{
   window.requests=[];window.messages=[];window.admin=false;window.allow=true;
   window.request=async (...args)=>{
    requests.push(args);
    if(args[1]==='rpc/complete_approved_opponent_deletion')return true;
    if(args[0]==='GET')return [
     {id:'n1',event_type:'decided',message:'<img src=x onerror=alert(1)>',read_at:null},
     {id:'n2',event_type:'completed',message:'Deletion completed',read_at:'2026-11-07T00:00:00Z'}
    ];
    return [];
   };
   window.refresh=async()=>{};
  });
  await page.evaluate(s=>{const el=document.createElement('script');el.textContent=s;document.body.appendChild(el)},source);
  await page.evaluate(async()=>{
   window.inbox=Next11OpponentReview({
    request:window.request,userId:()=> '00000000-0000-0000-0000-00000000a002',
    isAdmin:()=>window.admin,confirm:async()=>window.allow,
    notify:s=>window.messages.push(s),refresh:window.refresh
   });
   document.querySelector('#inbox').innerHTML=inbox.render(await inbox.load());
  });
  assert.equal(await page.locator('#inbox li').count(),2);
  assert.equal(await page.locator('#inbox img').count(),0,'Message must be escaped, not parsed as HTML');
  assert.equal(await page.locator('#inbox [data-mark-read]').count(),1);
  await page.evaluate(async()=>{await inbox.markRead('n1')});
  let calls=await page.evaluate(()=>requests);
  assert.equal(calls[1][0],'PATCH');
  assert.equal(calls[1][3].recipient_id,'eq.00000000-0000-0000-0000-00000000a002');
  await page.evaluate(async()=>{try{await inbox.completeDeletion('request-1')}catch(e){window.denied=e.message}});
  assert.match(await page.evaluate(()=>denied),/Administrator/);
  assert.equal((await page.evaluate(()=>requests)).filter(x=>x[1].startsWith('rpc/')).length,0);
  await page.evaluate(async()=>{admin=true;allow=false;await inbox.completeDeletion('request-1')});
  assert.equal((await page.evaluate(()=>requests)).filter(x=>x[1].startsWith('rpc/')).length,0);
  await page.evaluate(async()=>{allow=true;await inbox.completeDeletion('request-1')});
  calls=await page.evaluate(()=>requests);
  assert.equal(calls.at(-1)[1],'rpc/complete_approved_opponent_deletion');
  assert.deepEqual(calls.at(-1)[2],{p_request_id:'request-1'});
  assert.equal((await page.evaluate(()=>messages)).length,1);
  assert(!calls.some(x=>x[1]==='opponents'),'No direct opponent mutations allowed');
  console.log('PASS: browser inbox escaping, unread control, RLS filter, admin gate, cancel and completion RPC');
 } finally {await browser.close()}
})().catch(e=>{console.error(e);process.exitCode=1});

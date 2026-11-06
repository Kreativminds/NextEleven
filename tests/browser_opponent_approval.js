// Browser acceptance of user proposal/deletion requests and admin decisions.
// Uses the actual application functions with mocked transport, no production access.
const {chromium}=require('playwright');
const fs=require('node:fs');
const assert=require('node:assert/strict');
const html=fs.readFileSync(require('node:path').join(__dirname,'..','index.html'),'utf8');
const start=html.indexOf('async function requestOpponentAddition()');
const end=html.indexOf('// ── TRAINING SESSIONS',start);
assert(start>=0&&end>start,'Opponent request handlers present');
(async()=>{
 const browser=await chromium.launch({headless:true});
 try {
  const page=await browser.newPage();
  await page.setContent('<div id="stab-panel-opponents"></div>');
  await page.evaluate(()=>{
   window.calls=[];window.messages=[];window.answers=[];window.confirms=[];
   window.Auth={isLoggedIn:()=>true,getUserId:()=> '00000000-0000-0000-0000-00000000a002'};
   window.Sync={isConfigured:()=>true,supabaseRequest:async(method,table,payload,filter)=>{calls.push({method,table,payload,filter});return [{id:'reviewed'}]}};
   window.DB={get:async()=>({opponentName:'SL Olivais'})};
   window.Toast={show:s=>messages.push(s),error:s=>messages.push('ERROR:'+s)};
   window.renderOpponentsTab=async()=>{};
   window.prompt=()=>answers.shift();window.confirm=()=>confirms.shift();
  });
  await page.evaluate(source=>{let s=document.createElement('script');s.textContent=source;document.body.appendChild(s)},html.slice(start,end));
  await page.evaluate(async()=>{answers.push('New Federation Club','Official reference pending');confirms.push(false);await requestOpponentAddition()});
  let calls=await page.evaluate(()=>calls);
  assert.equal(calls[0].table,'opponent_addition_requests');
  assert.equal(calls[0].payload.proposed_type,'federation');
  assert.equal(calls[0].payload.requester_id,'00000000-0000-0000-0000-00000000a002');
  await page.evaluate(async()=>{answers.push('Village Local Team','Local amateur side');confirms.push(true);await requestOpponentAddition()});
  calls=await page.evaluate(()=>calls);
  assert.equal(calls[1].payload.proposed_type,'local');
  await page.evaluate(async()=>{answers.push('Duplicate opponent');await requestOpponentDeletion(9002)});
  calls=await page.evaluate(()=>calls);
  assert.equal(calls[2].table,'opponent_deletion_requests');
  assert.equal(calls[2].payload.opponent_local_id,'9002');
  await page.evaluate(async()=>{answers.push('Rejected, active fixtures');await reviewOpponentDeletionRequest('request-id',false)});
  calls=await page.evaluate(()=>calls);
  assert.equal(calls[3].payload.status,'rejected');
  assert.equal(calls[3].payload.decision_reason,'Rejected, active fixtures');
  await page.evaluate(async()=>{answers.push('Not registered in official federation');await reviewOpponentAdditionRequest('request-id','rejected')});
  calls=await page.evaluate(()=>calls);
  assert.equal(calls[4].payload.status,'rejected');
  assert.equal(calls[4].payload.decision_reason,'Not registered in official federation');
  assert(!calls.some(c=>c.table==='opponents'&&c.method!=='GET'),'No direct opponent deletion or mutation');
  console.log('PASS: Chromium proposal/local classification, deletion request, rejection reasons, no direct deletion');
 }finally{await browser.close()}
})().catch(e=>{console.error(e);process.exitCode=1});

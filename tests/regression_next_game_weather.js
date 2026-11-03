// Regression tests for the next-match weather forecast on the public
// team page (team.html's #nextGameWeather widget + renderNextGameWeather).
//
// Covers:
//   1. Home game with season homeGroundLat/Lng set + a mocked Open-Meteo
//      response → the widget renders icon/temp/rain text.
//   2. Away game uses the GAME's opponentLat/opponentLng, not the season's
//      home-ground coordinates — proven by inspecting the actual
//      Open-Meteo request URL.
//   3. No coordinates saved at all → widget stays empty, no page error,
//      and (confirmed separately) no Open-Meteo request is even made.
//   4. A match more than ~16 days out → widget stays empty and no
//      Open-Meteo request is made (the date-range guard short-circuits
//      before ever hitting the network).
//   5. Open-Meteo unreachable/failing → widget stays empty, no page error
//      (graceful degradation — a missing forecast is never shown as a
//      broken widget).
//
// Drives team.html directly via Playwright, exactly like the other
// regression tests in this folder, mocking both the get_public_team_data
// RPC and the Open-Meteo forecast endpoint.
//
// Run: node tests/regression_next_game_weather.js
const { chromium } = require('playwright');
const path = require('path');

const PAGE_URL = 'file://' + path.resolve(__dirname, '../team.html') + '?token=test';

function isoDate(daysFromNow) {
  const d = new Date();
  d.setDate(d.getDate() + daysFromNow);
  return d.toISOString().slice(0, 10);
}

function baseData(overrides) {
  return Object.assign({
    appBranding: { mainLogo: null },
    season: { seasonName: '2026/27', clubName: 'SLO Benfica', ageGroup: 'Sub-14', status: 'active', clubLogoUrl: null, homeGroundLat: null, homeGroundLng: null },
    privacy: { showNameMode: 'full', showPlayerStats: true },
    lineup: [], players: [], gamePlayers: [],
    availability: { available: 0, unavailable: 0, unavailablePlayers: [] },
    tournaments: [], seasonHighlights: [], previousAchievements: [], previousSeasons: [],
    seasonStory: null, classification: null,
  }, overrides);
}

function mockOpenMeteoDaily() {
  return { time: ['x'], weathercode: [0], temperature_2m_max: [22], temperature_2m_min: [14], precipitation_probability_max: [10] };
}

async function run(label, { data, openMeteoBody, openMeteoFail }) {
  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: 420, height: 1400 } });
  const failures = [];
  const check = (msg, cond) => { if (!cond) failures.push(msg); console.log((cond ? 'PASS' : 'FAIL') + ' — [' + label + '] ' + msg); };

  let weatherRequestUrl = null;
  page.on('pageerror', e => failures.push('pageerror: ' + e.message));
  await page.addInitScript(() => { try { localStorage.setItem('nexteleven_team_lang', 'en'); } catch (e) {} });
  await page.route('**/rpc/get_public_team_data', route => route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify(data) }));
  await page.route('**/api.open-meteo.com/**', route => {
    weatherRequestUrl = route.request().url();
    if (openMeteoFail) { route.abort('failed'); return; }
    route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify({ daily: openMeteoBody }) });
  });

  await page.goto(PAGE_URL);
  await page.waitForTimeout(800);
  const widgetHtml = await page.evaluate(() => document.getElementById('nextGameWeather')?.innerHTML || '');

  return { browser, check, failures, weatherRequestUrl, widgetHtml };
}

(async () => {
  const allFailures = [];

  // ── Test 1: home game, season coordinates set, forecast in range ──
  {
    const data = baseData({
      season: { seasonName: 'S', clubName: 'C', ageGroup: 'U14', status: 'active', clubLogoUrl: null, homeGroundLat: '38.7', homeGroundLng: '-9.1' },
      games: [{ gameId: 1, date: isoDate(3), gameTime: '15:00', opponent: 'Opp A', homeAway: 'Home', competitionType: 'League', competitionName: 'Liga', opponentScore: null, ourScore: null, guestPlayers: [], goalEvents: [], goalScorers: [], cardEvents: [], opponentMapUrl: null, opponentLat: null, opponentLng: null }],
    });
    const { browser, check, failures, weatherRequestUrl, widgetHtml } = await run('home-with-coords', { data, openMeteoBody: mockOpenMeteoDaily() });
    check('widget shows the mocked forecast (sun icon + temps + rain %)', /22.*14.*10%/s.test(widgetHtml) && widgetHtml.includes('☀️'));
    check('request used the SEASON home-ground coordinates', !!weatherRequestUrl && weatherRequestUrl.includes('latitude=38.7') && weatherRequestUrl.includes('longitude=-9.1'));
    allFailures.push(...failures);
    await browser.close();
  }

  // ── Test 2: away game uses the GAME's opponent coordinates ──
  {
    const data = baseData({
      season: { seasonName: 'S', clubName: 'C', ageGroup: 'U14', status: 'active', clubLogoUrl: null, homeGroundLat: '38.7', homeGroundLng: '-9.1' },
      games: [{ gameId: 2, date: isoDate(5), gameTime: '15:00', opponent: 'Opp B', homeAway: 'Away', competitionType: 'League', competitionName: 'Liga', opponentScore: null, ourScore: null, guestPlayers: [], goalEvents: [], goalScorers: [], cardEvents: [], opponentMapUrl: null, opponentLat: '40.2', opponentLng: '-8.4' }],
    });
    const { browser, check, failures, weatherRequestUrl, widgetHtml } = await run('away-with-opponent-coords', { data, openMeteoBody: mockOpenMeteoDaily() });
    check('widget shows the mocked forecast', widgetHtml.includes('☀️'));
    check('request used the OPPONENT venue coordinates, not the home ground', !!weatherRequestUrl && weatherRequestUrl.includes('latitude=40.2') && weatherRequestUrl.includes('longitude=-8.4'));
    check('request did NOT use the season home-ground coordinates', !weatherRequestUrl.includes('latitude=38.7'));
    allFailures.push(...failures);
    await browser.close();
  }

  // ── Test 3: no coordinates saved anywhere → stays empty, no crash ──
  {
    const data = baseData({
      games: [{ gameId: 3, date: isoDate(2), gameTime: '15:00', opponent: 'Opp C', homeAway: 'Home', competitionType: 'League', competitionName: 'Liga', opponentScore: null, ourScore: null, guestPlayers: [], goalEvents: [], goalScorers: [], cardEvents: [], opponentMapUrl: null, opponentLat: null, opponentLng: null }],
    });
    const { browser, check, failures, weatherRequestUrl, widgetHtml } = await run('no-coords', { data, openMeteoBody: mockOpenMeteoDaily() });
    check('widget stays empty when no coordinates are saved', widgetHtml.trim() === '');
    check('no Open-Meteo request is made without coordinates', weatherRequestUrl === null);
    allFailures.push(...failures);
    await browser.close();
  }

  // ── Test 4: match far beyond the forecast horizon → stays empty, no request ──
  {
    const data = baseData({
      season: { seasonName: 'S', clubName: 'C', ageGroup: 'U14', status: 'active', clubLogoUrl: null, homeGroundLat: '38.7', homeGroundLng: '-9.1' },
      games: [{ gameId: 4, date: isoDate(40), gameTime: '15:00', opponent: 'Opp D', homeAway: 'Home', competitionType: 'League', competitionName: 'Liga', opponentScore: null, ourScore: null, guestPlayers: [], goalEvents: [], goalScorers: [], cardEvents: [], opponentMapUrl: null, opponentLat: null, opponentLng: null }],
    });
    const { browser, check, failures, weatherRequestUrl, widgetHtml } = await run('too-far-out', { data, openMeteoBody: mockOpenMeteoDaily() });
    check('widget stays empty for a match far beyond the forecast horizon', widgetHtml.trim() === '');
    check('no Open-Meteo request is made for an out-of-range date', weatherRequestUrl === null);
    allFailures.push(...failures);
    await browser.close();
  }

  // ── Test 5: Open-Meteo unreachable → stays empty, no page error ──
  {
    const data = baseData({
      season: { seasonName: 'S', clubName: 'C', ageGroup: 'U14', status: 'active', clubLogoUrl: null, homeGroundLat: '38.7', homeGroundLng: '-9.1' },
      games: [{ gameId: 5, date: isoDate(1), gameTime: '15:00', opponent: 'Opp E', homeAway: 'Home', competitionType: 'League', competitionName: 'Liga', opponentScore: null, ourScore: null, guestPlayers: [], goalEvents: [], goalScorers: [], cardEvents: [], opponentMapUrl: null, opponentLat: null, opponentLng: null }],
    });
    const { browser, check, failures, widgetHtml } = await run('network-failure', { data, openMeteoFail: true });
    check('widget stays empty when the forecast request fails', widgetHtml.trim() === '');
    check('no page error was thrown', !failures.some(f => f.startsWith('pageerror')));
    allFailures.push(...failures);
    await browser.close();
  }

  console.log('\n' + (allFailures.length ? allFailures.length + ' FAILURE(S):\n' + allFailures.join('\n') : 'All checks passed.'));
  process.exit(allFailures.length ? 1 : 0);
})();

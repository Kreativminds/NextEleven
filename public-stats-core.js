// ============================================================================
// public-stats-core.js
// ============================================================================
// DUPLICATED TECHNICAL DEBT — READ BEFORE EDITING
//
// This file exists because team.html (the public, no-login share page)
// cannot import from or run alongside the main app's single giant inline
// <script> (football_tracker_v2.html / index.html), which has no module
// system and relies on everything being globally scoped for inline
// onclick="..." handlers throughout the HTML. Converting even a small
// piece of that file to an ES module was assessed as a real regression
// risk not worth taking for this feature.
//
// The functions below are copied VERBATIM (not reimplemented) from the
// main app, specifically:
//   - gameSortKey            (main app, global scope)
//   - Calc.teamGoals
//   - Calc.result
//   - Calc.homeAwayScore
//   - Calc.teamSeasonStats
//   - getTournamentOutcome   (adapted from async/DB.getAll to sync/array —
//                             see note above that function below)
//
// A trimmed public version of playerSeasonStats is included, computing
// ONLY appearances/goals/assists — the fields the approved public RPC
// actually returns. It intentionally does NOT compute minutes, cards, or
// Player of the Match, since those fields (role, yellowCards, redCards,
// playedFullGame in full, playerOfTheMatch) were deliberately excluded
// from get_public_team_data's return shape as not part of the approved
// public stat list. If the main app's real playerSeasonStats logic ever
// changes for goals/assists specifically, THIS FILE MUST BE UPDATED TO
// MATCH — that is the real, accepted cost of this duplication.
//
// If this app is ever restructured to support real ES modules, this file
// should be deleted and both team.html and the main app should import a
// single shared source instead.
// ============================================================================

function gameSortKey(game) {
  if (!game || !game.date) return 0;
  return new Date(`${game.date}T${game.gameTime || '00:00'}`).getTime();
}

function teamGoals(gpRecords, game) {
  const playerGoals = gpRecords.filter(r => r.calledUp).reduce((s,r) => s + (parseInt(r.goals)||0), 0);
  const ownGoals = game ? (parseInt(game.ownGoalsForUs)||0) : 0;
  return playerGoals + ownGoals;
}

// Official FIFA/UEFA convention: a match decided on penalties after a draw
// is recorded as a DRAW in the result/statistics — goals, goal difference,
// and W/D/L all reflect the actual scoreline. The shootout only ever
// decides progression, never the recorded result. The 'game' parameter is
// accepted for signature parity with the main app's call sites but unused
// here, matching the main app exactly.
function result(ourGoals, theirGoals, game) {
  const o = parseInt(ourGoals)||0, t = parseInt(theirGoals)||0;
  return o > t ? 'W' : o < t ? 'L' : 'D';
}

// Returns the score in correct football convention: Home — Away.
function homeAwayScore(homeAway, ourGoals, theirGoals, neutralSide) {
  const o = parseInt(ourGoals)||0, t = parseInt(theirGoals)||0;
  if (homeAway === 'Away') return { home: t, away: o };
  if (homeAway === 'Neutral' && neutralSide === 'Away') return { home: t, away: o };
  return { home: o, away: t };
}

function teamSeasonStats(games, allGP) {
  const s = {
    played:0, wins:0, draws:0, losses:0,
    goalsFor:0, goalsAgainst:0,
    cleanSheets:0, failedToScore:0,
  };

  const sorted = [...games].sort((a,b)=>gameSortKey(a)-gameSortKey(b));

  sorted.forEach(g => {
    const gps = allGP.filter(r => r.gameId === g.gameId);
    const our = teamGoals(gps, g);
    const their = parseInt(g.opponentScore)||0;
    const res = result(our, their, g);

    s.played++;
    s.goalsFor += our;
    s.goalsAgainst += their;

    if (res==='W') s.wins++;
    else if (res==='D') s.draws++;
    else s.losses++;

    if (their===0) s.cleanSheets++;
    if (our===0) s.failedToScore++;
  });

  s.goalDiff = s.goalsFor - s.goalsAgainst;
  return s;
}

// Post-match goal breakdown for the "just finished" match summary (Parents
// Page pinned card; the main app has an equivalent read-only summary on the
// Game Detail Goals tab, built from this exact function copied verbatim —
// see the duplication note at the top of this file).
//
// ourGoals: one entry per goal scored BY OUR TEAM (including own goals),
// each { name, minute }. name is the scorer's fullName/name, or null for an
// own goal (no scorer on our own roster) or an unresolved player record —
// callers should fall back to a generic "Unknown"/own-goal label, same as
// the existing live-card renderer already does. minute is the elapsed
// minutes since kickoff, derived from goalEvents' scoredAt, or null when
// it can't be determined — no kickoff time known, no matching goalEvents
// row (goalEvents is OPTIONAL here: on the public Parents Page today it is
// always empty, since get_public_team_data doesn't return it yet — every
// our-team goal then simply gets minute:null, which is exactly the spec's
// "no minute recorded" fallback, not a bug), or a value outside a
// plausible match window (a correction entered long after the fact).
//
// opponentGoals: one entry per goal scored BY THE OPPONENT, each just
// { minute }, always minute:null today — the app has never tracked a
// per-opponent-goal event (not even a timestamp), only the running total
// game.opponentScore, and there is no opposing scorer name to show at all
// (by design — callers render a generic placeholder label instead, e.g.
// I18n 'opponent_goal' / team.html's STRINGS.opponent_goal).
const MATCH_SUMMARY_MAX_PLAUSIBLE_MINUTE = 150; // 90 + extra time + stoppage; keeps a late data-entry timestamp from showing a nonsense "minute"
function buildMatchGoalSummary(game, gpRecords, players, tempPlayers, goalEvents) {
  players = players || [];
  tempPlayers = tempPlayers || [];
  goalEvents = (goalEvents || []).filter(e => e && !e.isDeleted);

  const kickoffIso = game && (game.actualKickoffAt || (game.date ? `${game.date}T${game.gameTime || '00:00'}` : null));
  const kickoff = kickoffIso ? new Date(kickoffIso) : null;
  const hasKickoff = !!(kickoff && !isNaN(kickoff));

  function minuteFromScoredAt(scoredAt) {
    if (!hasKickoff || !scoredAt) return null;
    const t = new Date(scoredAt);
    if (isNaN(t)) return null;
    const mins = Math.round((t - kickoff) / 60000);
    if (mins < 0 || mins > MATCH_SUMMARY_MAX_PLAUSIBLE_MINUTE) return null;
    return mins;
  }

  const ourGoals = [];
  (gpRecords || []).filter(r => r.calledUp && (parseInt(r.goals)||0) > 0).forEach(r => {
    const isTemp = r.playerId == null;
    const scorerType = isTemp ? 'temp' : 'player';
    const scorerId = isTemp ? r.tempPlayerId : r.playerId;
    const n = parseInt(r.goals) || 0;
    const name = isTemp
      ? (tempPlayers.find(t => t.tempPlayerId === scorerId) || {}).name || null
      : (players.find(p => p.playerId === scorerId) || {}).fullName || null;
    const events = goalEvents
      .filter(e => e.scorerId === scorerId && e.scorerType === scorerType)
      .sort((a,b) => new Date(a.scoredAt) - new Date(b.scoredAt));
    for (let i = 0; i < n; i++) {
      ourGoals.push({ name, minute: events[i] ? minuteFromScoredAt(events[i].scoredAt) : null });
    }
  });
  // Own goals (ball into the opponent's net off one of THEIR players) count
  // FOR us but have no scorer on our own roster — same "Own goal" treatment
  // the existing live card already uses, never a named player.
  const ownGoals = parseInt(game && game.ownGoalsForUs) || 0;
  for (let i = 0; i < ownGoals; i++) ourGoals.push({ name: null, isOwnGoal: true, minute: null });
  // Known minutes first (ascending), unknown-minute goals trail at the end —
  // never interleaved as if minute:null meant "minute 0".
  ourGoals.sort((a,b) => (a.minute==null?1:0) - (b.minute==null?1:0) || (a.minute||0) - (b.minute||0));

  const theirCount = parseInt(game && game.opponentScore) || 0;
  const opponentGoals = [];
  for (let i = 0; i < theirCount; i++) opponentGoals.push({ minute: null });

  return { ourGoals, opponentGoals };
}

// Trimmed public version — appearances/starts/goals/assists/cards, matching
// exactly what get_public_team_data's gamePlayers rows contain. Does NOT
// compute minutes or MOTM (those fields are not returned by the public RPC
// and are out of scope for the public page per approved spec).
// 'started' mirrors the main app's playerSeasonStats exactly: role==='Starter'
// on a calledUp row — a bench/unused call-up never counts, same as there.
//
// yellowCards/redCards (added 2026-10-26, card-tracking feature) are summed
// from gp.cardYellowCount/gp.cardRedCount — per-game-player counts the RPC
// computes server-side FROM THE card_events TABLE, not from the older
// manual gp.yellowCards/gp.redCards integer fields the admin app's own
// playerSeasonStats still reads elsewhere. Per Victor's instruction: "All
// disciplinary totals must be calculated from recorded events" — the new
// event-sourced table is the only source of truth for any total shown here,
// public or admin, going forward. A second-yellow dismissal counts toward
// BOTH tallies (one caution + one sending-off), same convention as the
// admin Cards tab's own computeCardTotals().
function playerPublicStats(playerId, games, allGP) {
  let calledUp=0, started=0, goals=0, assists=0, yellowCards=0, redCards=0;
  const positionCounts = {};
  const positionMostRecentKey = {};
  games.forEach(g => {
    const gp = allGP.find(r => r.gameId===g.gameId && r.playerId===playerId);
    if (!gp || !gp.calledUp) return;
    calledUp++;
    if (gp.role === 'Starter') started++;
    goals += parseInt(gp.goals)||0;
    assists += parseInt(gp.assists)||0;
    yellowCards += parseInt(gp.cardYellowCount)||0;
    redCards += parseInt(gp.cardRedCount)||0;
    if (gp.positionPlayed) {
      positionCounts[gp.positionPlayed] = (positionCounts[gp.positionPlayed]||0) + 1;
      const key = gameSortKey(g);
      if (!positionMostRecentKey[gp.positionPlayed] || key > positionMostRecentKey[gp.positionPlayed]) {
        positionMostRecentKey[gp.positionPlayed] = key;
      }
    }
  });

  let mostPlayedPosition = null, bestCount = -1, bestRecency = -1;
  Object.keys(positionCounts).forEach(pos => {
    const count = positionCounts[pos];
    const recency = positionMostRecentKey[pos];
    if (count > bestCount || (count === bestCount && recency > bestRecency)) {
      mostPlayedPosition = pos; bestCount = count; bestRecency = recency;
    }
  });

  return { calledUp, started, goals, assists, yellowCards, redCards, mostPlayedPosition };
}

// Adapted from the main app's async getTournamentOutcome(tournament),
// which internally calls DB.getAll('games', ...) and DB.getAll
// ('gamePlayers', ...) against IndexedDB. The public page has no
// IndexedDB — it already has every game and gamePlayers row for the
// season in memory from the RPC response — so this version takes those
// arrays directly instead of fetching them. The actual outcome-derivation
// logic (stage-priority order, Winner vs Runner-up, medal emoji per
// bracket tier) is otherwise identical to the main app's version.
//
// Labels are inlined here in EN/PT rather than calling I18n.t(), since
// team.html does not load the main app's translation table. If the main
// app's outcome wording changes, update both places.
function getTournamentOutcomePublic(tournament, allGames, allGP, lang) {
  const t = (en, pt) => (lang === 'PT' ? pt : en);
  const tournGames = allGames.filter(g => g.tournamentId === tournament.tournamentId);
  if (!tournGames.length) {
    return { emoji: '', label: t('No games yet.', 'Ainda sem jogos.'), status: 'none' };
  }

  const stagePriority = ['Gold Final','Final','Silver Final','Bronze Final','Semi-Final','Quarter-Final','Round of 16','Group Stage'];
  const gamesWithStage = tournGames.filter(g => g.stage);
  let furthestGame = null;
  for (const stage of stagePriority) {
    furthestGame = gamesWithStage.find(g => g.stage === stage);
    if (furthestGame) break;
  }

  if (!furthestGame) {
    return { emoji: '', label: t('Participant', 'Participante'), status: 'unknown' };
  }

  const gps = allGP.filter(r => r.gameId === furthestGame.gameId);
  const ourScore = teamGoals(gps, furthestGame);
  const theirScore = parseInt(furthestGame.opponentScore) || 0;
  const res = result(ourScore, theirScore, furthestGame);
  const isFinal = furthestGame.stage.includes('Final');
  const won = res === 'W';
  const stage = furthestGame.stage;

  if (isFinal && won) {
    const emoji = stage === 'Gold Final' ? '🏆' : stage === 'Silver Final' ? '🥈' : stage === 'Bronze Final' ? '🥉' : '🏆';
    const label = stage === 'Final'
      ? t('Champion', 'Campeão')
      : t(`${stage} Winner`, `Vencedor ${stage}`);
    return { emoji, label, status: 'won' };
  }
  if (isFinal && !won) {
    const emoji = stage === 'Gold Final' ? '🥈' : stage === 'Silver Final' ? '🥉' : '';
    const label = stage === 'Final'
      ? t('Finalist', 'Finalista')
      : t(`${stage} Runner-up`, `Vice-campeão ${stage}`);
    return { emoji, label, status: 'runnerup' };
  }

  const stageLabels = {
    'Semi-Final': t('Semi-finalist', 'Meia-finalista'),
    'Quarter-Final': t('Quarter-finalist', 'Quartos-finalista'),
    'Round of 16': t('Round of 16', 'Oitavos de Final'),
    'Group Stage': t('Group Stage', 'Fase de Grupos'),
  };
  return { emoji: '', label: stageLabels[stage] || t('Participant', 'Participante'), status: 'eliminated' };
}

// Computes each player's NEXT birthday from today, correctly wrapping
// the calendar year (a birthday last month is genuinely ~11 months
// away, not negative). Returns one entry per player with a DOB, sorted
// by closeness, so callers can slice the top 3, or filter for "today"
// / "within 7 days" without recomputing anything.
function upcomingBirthdays(players, referenceDate) {
  const today = referenceDate || new Date();
  today.setHours(0,0,0,0);

  return players
    .filter(p => p.dateOfBirth)
    .map(p => {
      const dob = new Date(p.dateOfBirth + 'T00:00:00');
      if (isNaN(dob)) return null;

      let nextBirthday = new Date(today.getFullYear(), dob.getMonth(), dob.getDate());
      if (nextBirthday < today) {
        nextBirthday = new Date(today.getFullYear() + 1, dob.getMonth(), dob.getDate());
      }
      const daysUntil = Math.round((nextBirthday - today) / (1000*60*60*24));
      const turningAge = nextBirthday.getFullYear() - dob.getFullYear();

      return {
        playerId: p.playerId,
        fullName: p.fullName,
        shirtNumber: p.shirtNumber,
        daysUntil,
        turningAge,
        isToday: daysUntil === 0,
        isThisWeek: daysUntil > 0 && daysUntil <= 7,
      };
    })
    .filter(b => b !== null)
    .sort((a,b) => a.daysUntil - b.daysUntil);
}


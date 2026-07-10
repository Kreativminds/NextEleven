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

// Trimmed public version — appearances/goals/assists only, matching
// exactly what get_public_team_data's gamePlayers rows contain. Does NOT
// compute minutes, cards, or MOTM (those fields are not returned by the
// public RPC and are out of scope for the public page per approved spec).
function playerPublicStats(playerId, games, allGP) {
  let calledUp=0, goals=0, assists=0;
  games.forEach(g => {
    const gp = allGP.find(r => r.gameId===g.gameId && r.playerId===playerId);
    if (!gp || !gp.calledUp) return;
    calledUp++;
    goals += parseInt(gp.goals)||0;
    assists += parseInt(gp.assists)||0;
  });
  return { calledUp, goals, assists };
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

-- Migration: fix_card_red_count_direct_red
-- Project: wicydcvdakqopodbxtrl
--
-- NOT YET APPLIED. Full redefinition of get_public_team_data — the ONLY
-- change from the live function is the cardRedCount filter at the bottom
-- of the gamePlayers block: 'red' -> 'direct_red'.
--
-- Why: the admin app has always recorded a direct red card with
-- cardType = 'direct_red' (see cardTypeIcon()/selectCardType() in
-- index.html) — it never writes the bare string 'red'. This function's
-- cardRedCount was matching 'red', so a direct red card was never counted
-- toward a player's season red-card total on the Parents Page. The
-- matching fix on the display side (team.html's cardEventIcon(), which
-- had the same 'red' vs 'direct_red' mismatch for the match-level card
-- icon) is in this PR's code changes, not here.
--
-- No production card_events row has cardType = 'direct_red' yet (verified
-- — all 3 existing rows are 'yellow'), so this is a latent bug fix, not a
-- visible-today one. Safe to apply independently of 001.

create or replace function public.get_public_team_data(p_token text)
 returns jsonb
 language plpgsql
 security definer
 set search_path to 'public'
as $function$
declare
  v_link record;
  v_season_payload jsonb;
  v_result jsonb;
  v_wins int := 0;
  v_draws int := 0;
  v_losses int := 0;
  v_goals_for int := 0;
  v_games_played int := 0;
  v_top_tournament_title text := null;
  v_season_story text := null;
  v_club_name text;
  v_season_name text;
  v_app_main_logo text;
begin
  select * into v_link from team_share_links where share_token = p_token and enabled = true;
  if not found then return null; end if;

  select payload into v_season_payload from seasons
    where user_id = v_link.user_id and (payload->>'seasonId')::int = v_link.season_id and deleted_at is null
    limit 1;
  if v_season_payload is null then return null; end if;

  v_club_name := v_season_payload->>'clubName';
  v_season_name := v_season_payload->>'seasonName';

  select payload->>'mainLogo' into v_app_main_logo
    from app_branding
    where user_id = v_link.user_id
    limit 1;

  select
      coalesce(count(*) filter (where og.our > (g.payload->>'opponentScore')::int), 0),
      coalesce(count(*) filter (where og.our < (g.payload->>'opponentScore')::int), 0),
      coalesce(sum(og.our), 0),
      coalesce(count(*), 0)
    into v_wins, v_losses, v_goals_for, v_games_played
    from games g
    cross join lateral (
      select coalesce(
        nullif(g.payload->>'ourScore','')::int,
        coalesce((
          select sum((gp.payload->>'goals')::int)
          from game_players gp
          where gp.user_id = g.user_id and gp.deleted_at is null
            and (gp.payload->>'gameId')::int = (g.payload->>'gameId')::int
        ), 0) + coalesce((g.payload->>'ownGoalsForUs')::int, 0)
      ) as our
    ) og
    where g.user_id = v_link.user_id and (g.payload->>'seasonId')::int = v_link.season_id and g.deleted_at is null
      and g.payload->>'date' is not null and (g.payload->>'date')::date <= current_date;

  select payload->>'title' into v_top_tournament_title
    from achievements
    where user_id = v_link.user_id and (payload->>'seasonId')::int = v_link.season_id
      and payload->>'category' = 'Trophy' and (payload->>'dismissed') is distinct from 'true' and deleted_at is null
    order by payload->>'date' desc nulls last
    limit 1;

  if v_games_played > 0 then
    v_season_story := coalesce(v_club_name,'The team') || ' completed the ' || coalesce(v_season_name,'season') ||
      ' season with ' || v_wins || ' win' || (case when v_wins != 1 then 's' else '' end) ||
      ' from ' || v_games_played || ' match' || (case when v_games_played != 1 then 'es' else '' end) ||
      ', scoring ' || v_goals_for || ' goal' || (case when v_goals_for != 1 then 's' else '' end) || '.';
    if v_top_tournament_title is not null then
      v_season_story := v_season_story || ' The team also ' ||
        (case when v_top_tournament_title ilike '%winner%' or v_top_tournament_title ilike '%champion%'
              then 'won the ' || v_top_tournament_title
              else 'achieved ' || v_top_tournament_title
              end) || '.';
    end if;
  end if;

  select jsonb_build_object(
      'appBranding', jsonb_build_object('mainLogo', v_app_main_logo),
      'season', jsonb_build_object(
            'seasonName', v_season_payload->>'seasonName',
            'clubName', v_season_payload->>'clubName',
            'ageGroup', v_season_payload->>'ageGroup',
            'status', coalesce(v_season_payload->>'status', 'active'),
            'clubLogoUrl', (
                select ct.payload->>'logoUrl'
                from public.club_teams ct
                where ct.user_id = v_link.user_id and ct.deleted_at is null
                  and (ct.payload->>'clubTeamId')::int = (v_season_payload->>'clubTeamId')::int
                limit 1
              )
          ),
      'privacy', jsonb_build_object('showNameMode', v_link.show_name_mode, 'showPlayerStats', v_link.show_player_stats),
      'lineup', (
          case when v_link.show_lineup = false then '[]'::jsonb else (
            select coalesce(jsonb_agg(jsonb_build_object(
                'gameId', payload->>'gameId', 'playerId', payload->>'playerId',
                'calledUp', payload->>'calledUp', 'role', payload->>'role', 'tempPlayerId', payload->>'tempPlayerId', 'positionPlayed', payload->>'positionPlayed', 'shirtNumberPlayed', payload->>'shirtNumberPlayed',
                'goals', case when v_link.show_live_player_details = true and exists (
                    select 1 from games g2
                    where g2.user_id = game_players.user_id and g2.deleted_at is null
                      and (g2.payload->>'gameId')::int = (game_players.payload->>'gameId')::int
                      and g2.payload->>'date' is not null and g2.payload->>'gameTime' is not null
                      and ((g2.payload->>'date') || 'T' || (g2.payload->>'gameTime'))::timestamp <= now()
                      and now() < ((g2.payload->>'date') || 'T' || (g2.payload->>'gameTime'))::timestamp
                        + (coalesce((g2.payload->>'matchDurationMins')::int, 90) + 15) * interval '1 minute'
                      ) then payload->>'goals' else null end
              )), '[]'::jsonb)
            from game_players
            where user_id = v_link.user_id and deleted_at is null
              and (payload->>'gameId')::int in (select (payload->>'gameId')::int from games where user_id = v_link.user_id and (payload->>'seasonId')::int = v_link.season_id and deleted_at is null)
            ) end
          ),
      'games', (
          select coalesce(jsonb_agg(jsonb_build_object(
              'gameId', payload->>'gameId', 'date', payload->>'date', 'gameTime', payload->>'gameTime',
              'opponent', payload->>'opponent', 'homeAway', payload->>'homeAway', 'neutralSide', payload->>'neutralSide',
              'competitionType', payload->>'competitionType', 'competitionName', payload->>'competitionName',
              'opponentScore', payload->>'opponentScore', 'ownGoalsForUs', payload->>'ownGoalsForUs',
              'ourScore', coalesce(
                  nullif(games.payload->>'ourScore','')::int,
                  coalesce((
                    select sum((gp.payload->>'goals')::int)
                    from game_players gp
                    where gp.user_id = games.user_id and gp.deleted_at is null
                      and (gp.payload->>'gameId')::int = (games.payload->>'gameId')::int
                    ), 0) + coalesce((games.payload->>'ownGoalsForUs')::int, 0)
                ),
              'ourPenaltyGoals', payload->>'ourPenaltyGoals', 'penaltiesForThem', payload->>'penaltiesForThem',
              'tournamentId', payload->>'tournamentId', 'stage', payload->>'stage', 'venue', payload->>'venue',
              'guestPlayers', (
                  select coalesce(jsonb_agg(jsonb_build_object(
                      'tempPlayerId', tp.payload->>'tempPlayerId',
                      'name', tp.payload->>'name',
                      'shirtNumber', tp.payload->>'shirtNumber',
                      'preferredPosition', tp.payload->>'preferredPosition'
                    )), '[]'::jsonb)
                  from temporary_players tp
                  where tp.user_id = v_link.user_id and tp.deleted_at is null
                    and exists (
                      select 1 from game_players gp
                      where gp.user_id = v_link.user_id and gp.deleted_at is null
                        and gp.payload->>'tempPlayerId' = tp.payload->>'tempPlayerId'
                        and gp.payload->>'calledUp' = 'true'
                        and (gp.payload->>'gameId')::int in (
                          select (payload->>'gameId')::int from games
                          where user_id = v_link.user_id and (payload->>'seasonId')::int = v_link.season_id and deleted_at is null
                          )
                      )
                  ),
              'opponentMapUrl', (
                  select o.payload->>'mapUrl'
                  from public.opponents o
                  where o.user_id = games.user_id and o.deleted_at is null
                    and lower(o.payload->>'opponentName') = lower(games.payload->>'opponent')
                  limit 1
                  ),
              'goalEvents', (
                  case when games.payload->>'date' is null or (games.payload->>'date')::date < (current_date - interval '3 days')::date then '[]'::jsonb else (
                    select coalesce(jsonb_agg(jsonb_build_object(
                        'scorerId', ge.payload->>'scorerId',
                        'scorerType', ge.payload->>'scorerType',
                        'scoredAt', ge.payload->>'scoredAt'
                      ) order by ge.payload->>'scoredAt'), '[]'::jsonb)
                    from goal_events ge
                    where ge.user_id = games.user_id and ge.deleted_at is null
                      and (ge.payload->>'gameId')::int = (games.payload->>'gameId')::int
                    ) end
                  ),
              'goalScorers', (
                  case when games.payload->>'date' is null or (games.payload->>'date')::date < (current_date - interval '3 days')::date then '[]'::jsonb else (
                    select coalesce(jsonb_agg(jsonb_build_object(
                        'playerId', gp2.payload->>'playerId',
                        'tempPlayerId', gp2.payload->>'tempPlayerId',
                        'calledUp', gp2.payload->>'calledUp',
                        'goals', gp2.payload->>'goals'
                      )), '[]'::jsonb)
                    from game_players gp2
                    where gp2.user_id = games.user_id and gp2.deleted_at is null
                      and (gp2.payload->>'gameId')::int = (games.payload->>'gameId')::int
                      and coalesce((gp2.payload->>'goals')::int, 0) > 0
                    ) end
                  ),
              'cardEvents', (
                  case when games.payload->>'date' is null or (games.payload->>'date')::date < (current_date - interval '3 days')::date then '[]'::jsonb else (
                    select coalesce(jsonb_agg(jsonb_build_object(
                        'team', ce.payload->>'team',
                        'scorerId', ce.payload->>'scorerId',
                        'scorerType', ce.payload->>'scorerType',
                        'opponentShirtNumber', ce.payload->>'opponentShirtNumber',
                        'opponentPlayerName', ce.payload->>'opponentPlayerName',
                        'cardType', ce.payload->>'cardType',
                        'minute', ce.payload->>'minute',
                        'stoppageMinute', ce.payload->>'stoppageMinute'
                      ) order by (ce.payload->>'minute')::int, coalesce((ce.payload->>'stoppageMinute')::int, 0)), '[]'::jsonb)
                    from card_events ce
                    where ce.user_id = games.user_id and ce.deleted_at is null
                      and (ce.payload->>'gameId')::int = (games.payload->>'gameId')::int
                    ) end
                  )
              ) order by payload->>'date'), '[]'::jsonb)
            from games where user_id = v_link.user_id and (payload->>'seasonId')::int = v_link.season_id and deleted_at is null
          ),
      'gamePlayers', (
          case when v_link.show_player_stats = false then '[]'::jsonb else (
            select coalesce(jsonb_agg(jsonb_build_object(
                'gameId', payload->>'gameId', 'playerId', payload->>'playerId', 'calledUp', payload->>'calledUp',
                'goals', payload->>'goals', 'assists', payload->>'assists', 'playedFullGame', payload->>'playedFullGame',
                'positionPlayed', payload->>'positionPlayed', 'role', payload->>'role',
                'cardYellowCount', (
                    select count(*) from card_events ce
                    where ce.user_id = game_players.user_id and ce.deleted_at is null
                      and (ce.payload->>'gameId')::int = (game_players.payload->>'gameId')::int
                      and ce.payload->>'team' = 'us' and ce.payload->>'scorerType' = 'player'
                      and (ce.payload->>'scorerId')::int = (game_players.payload->>'playerId')::int
                      and ce.payload->>'cardType' in ('yellow','second_yellow')
                  ),
                'cardRedCount', (
                    select count(*) from card_events ce
                    where ce.user_id = game_players.user_id and ce.deleted_at is null
                      and (ce.payload->>'gameId')::int = (game_players.payload->>'gameId')::int
                      and ce.payload->>'team' = 'us' and ce.payload->>'scorerType' = 'player'
                      and (ce.payload->>'scorerId')::int = (game_players.payload->>'playerId')::int
                      and ce.payload->>'cardType' in ('direct_red','second_yellow') -- FIX: was 'red'
                  )
              )), '[]'::jsonb)
            from game_players
            where user_id = v_link.user_id and deleted_at is null
              and (payload->>'gameId')::int in (select (payload->>'gameId')::int from games where user_id = v_link.user_id and (payload->>'seasonId')::int = v_link.season_id and deleted_at is null)
            ) end
          ),
      'players', (
          select coalesce(jsonb_agg(jsonb_build_object(
              'playerId', payload->>'playerId',
              'fullName', public.fmt_public_name(payload->>'fullName', v_link.show_name_mode),
              'shirtNumber', payload->>'shirtNumber', 'primaryPosition', payload->>'primaryPosition'
            ) order by (payload->>'shirtNumber')::int), '[]'::jsonb)
          from players
          where user_id = v_link.user_id and (payload->>'seasonId')::int = v_link.season_id and (payload->>'isActive')::boolean = true and deleted_at is null
          ),
      'birthdays', (
          select coalesce(jsonb_agg(jsonb_build_object(
              'playerId', b.player_id,
              'fullName', public.fmt_public_name(b.full_name, v_link.show_name_mode),
              'shirtNumber', b.shirt_number, 'daysUntil', b.days_until, 'turningAge', b.turning_age,
              'isToday', b.days_until = 0, 'isThisWeek', b.days_until > 0 and b.days_until <= 7,
              'birthdayMonth', b.birthday_month, 'birthdayDay', b.birthday_day
            ) order by b.days_until), '[]'::jsonb)
          from (
              select payload->>'playerId' as player_id, payload->>'fullName' as full_name, payload->>'shirtNumber' as shirt_number,
                extract(month from (payload->>'dateOfBirth')::date)::int as birthday_month,
                extract(day from (payload->>'dateOfBirth')::date)::int as birthday_day,
                case when make_date(extract(year from current_date)::int, extract(month from (payload->>'dateOfBirth')::date)::int, extract(day from (payload->>'dateOfBirth')::date)::int) >= current_date
                  then make_date(extract(year from current_date)::int, extract(month from (payload->>'dateOfBirth')::date)::int, extract(day from (payload->>'dateOfBirth')::date)::int) - current_date
                  else make_date(extract(year from current_date)::int + 1, extract(month from (payload->>'dateOfBirth')::date)::int, extract(day from (payload->>'dateOfBirth')::date)::int) - current_date
                  end as days_until,
                case when make_date(extract(year from current_date)::int, extract(month from (payload->>'dateOfBirth')::date)::int, extract(day from (payload->>'dateOfBirth')::date)::int) >= current_date
                  then extract(year from current_date)::int - extract(year from (payload->>'dateOfBirth')::date)::int
                  else extract(year from current_date)::int + 1 - extract(year from (payload->>'dateOfBirth')::date)::int
                  end as turning_age
              from players
              where user_id = v_link.user_id and (payload->>'seasonId')::int = v_link.season_id and (payload->>'isActive')::boolean = true and deleted_at is null and payload->>'dateOfBirth' is not null
              ) b
          ),
      'availability', (
          select jsonb_build_object(
              'available', (
                  select count(*) from players p
                  where p.user_id = v_link.user_id and (p.payload->>'seasonId')::int = v_link.season_id and (p.payload->>'isActive')::boolean = true and p.deleted_at is null
                    and not exists (
                      select 1 from injuries i
                      where i.user_id = v_link.user_id and i.deleted_at is null
                        and (i.payload->>'playerId')::int = (p.payload->>'playerId')::int
                        and i.payload->>'status' = 'Injured'
                        and not exists (
                          select 1 from injuries i2
                          where i2.user_id = i.user_id and i2.deleted_at is null
                            and i2.payload->>'injuryId' = i.payload->>'injuryId'
                            and (i2.payload->>'playerId')::int = (i.payload->>'playerId')::int
                            and i2.updated_at > i.updated_at
                          )
                      )
                  ),
              'unavailable', (
                  select count(*) from players p
                  where p.user_id = v_link.user_id and (p.payload->>'seasonId')::int = v_link.season_id and (p.payload->>'isActive')::boolean = true and p.deleted_at is null
                    and exists (
                      select 1 from injuries i
                      where i.user_id = v_link.user_id and i.deleted_at is null
                        and (i.payload->>'playerId')::int = (p.payload->>'playerId')::int
                        and i.payload->>'status' = 'Injured'
                        and not exists (
                          select 1 from injuries i2
                          where i2.user_id = i.user_id and i2.deleted_at is null
                            and i2.payload->>'injuryId' = i.payload->>'injuryId'
                            and (i2.payload->>'playerId')::int = (i.payload->>'playerId')::int
                            and i2.updated_at > i.updated_at
                          )
                      )
                  ),
              'unavailablePlayers', (
                  select coalesce(jsonb_agg(jsonb_build_object(
                      'playerId', p.payload->>'playerId',
                      'fullName', public.fmt_public_name(p.payload->>'fullName', v_link.show_name_mode),
                      'shirtNumber', p.payload->>'shirtNumber', 'primaryPosition', p.payload->>'primaryPosition'
                    )), '[]'::jsonb)
                  from players p
                  where p.user_id = v_link.user_id and (p.payload->>'seasonId')::int = v_link.season_id and (p.payload->>'isActive')::boolean = true and p.deleted_at is null
                    and exists (
                      select 1 from injuries i
                      where i.user_id = v_link.user_id and i.deleted_at is null
                        and (i.payload->>'playerId')::int = (p.payload->>'playerId')::int
                        and i.payload->>'status' = 'Injured'
                        and not exists (
                          select 1 from injuries i2
                          where i2.user_id = i.user_id and i2.deleted_at is null
                            and i2.payload->>'injuryId' = i.payload->>'injuryId'
                            and (i2.payload->>'playerId')::int = (i.payload->>'playerId')::int
                            and i2.updated_at > i.updated_at
                          )
                      )
                  )
              )
          ),
      'tournaments', (
          select coalesce(jsonb_agg(jsonb_build_object('tournamentId', payload->>'tournamentId', 'name', payload->>'name', 'location', payload->>'location', 'startDate', payload->>'startDate', 'endDate', payload->>'endDate')), '[]'::jsonb)
          from tournaments where user_id = v_link.user_id and (payload->>'seasonId')::int = v_link.season_id and deleted_at is null
          ),
      'seasonHighlights', (
          select coalesce(jsonb_agg(jsonb_build_object('title', title, 'date', date) order by date desc nulls last), '[]'::jsonb)
          from (
              select distinct payload->>'title' as title, payload->>'date' as date
              from achievements
              where user_id = v_link.user_id and (payload->>'seasonId')::int = v_link.season_id
                and payload->>'category' in ('Trophy','Team') and (payload->>'dismissed') is distinct from 'true' and deleted_at is null
              order by payload->>'date' desc nulls last
              limit 5
              ) highlights
          ),
      'previousAchievements', (
          select coalesce(jsonb_agg(jsonb_build_object('title', title, 'date', date)), '[]'::jsonb)
          from (
              select distinct payload->>'title' as title, payload->>'date' as date
              from achievements
              where user_id = v_link.user_id and (payload->>'seasonId')::int is distinct from v_link.season_id
                and payload->>'category' = 'Trophy' and (payload->>'autoGenerated')::boolean = true
                and (payload->>'dismissed') is distinct from 'true' and deleted_at is null
              ) unique_achievements
          ),
      'previousSeasons', (
          select coalesce(jsonb_agg(jsonb_build_object('seasonName', s.payload->>'seasonName', 'clubName', s.payload->>'clubName', 'shareToken', tsl.share_token) order by s.payload->>'seasonName' desc), '[]'::jsonb)
          from team_share_links tsl
          join seasons s on s.user_id = tsl.user_id and (s.payload->>'seasonId')::int = tsl.season_id and s.deleted_at is null
          where tsl.user_id = v_link.user_id and tsl.enabled = true and tsl.season_id != v_link.season_id
          ),
      'seasonStory', v_season_story,
      'classification', (
          select jsonb_build_object(
              'competitionType', cs.payload->>'competitionType',
              'competitionName', cs.payload->>'competitionName',
              'phase', cs.payload->>'phase',
              'series', cs.payload->>'series',
              'source', jsonb_build_object(
                  'name', cs.payload->'source'->>'name',
                  'url', cs.payload->'source'->>'url',
                  'publishedDate', cs.payload->'source'->>'publishedDate'
                ),
              'updatedAt', cs.payload->>'publishedAt',
              'rows', coalesce(cs.payload->'rows', '[]'::jsonb)
            )
          from classification_snapshots cs
          where cs.user_id = v_link.user_id
            and (cs.payload->>'seasonId')::int = v_link.season_id
            and cs.payload->>'publicationStatus' = 'published'
            and cs.deleted_at is null
          order by (cs.payload->>'publishedAt') desc nulls last
          limit 1
          )
      ) into v_result;

  return v_result;
end;
$function$;

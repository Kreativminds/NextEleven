-- Read-only candidate counts only. Never merge or strip squad suffixes automatically.
SELECT count(*) AS active_opponents,
 count(*) FILTER (WHERE payload->>'opponentName' ~* '(sub[ -]?[0-9]{1,2}|u[ -]?[0-9]{1,2}|divis[aã]o|s[eé]rie)') AS names_with_age_or_series,
 count(*) FILTER (WHERE payload->>'opponentName' ~* '("[A-Z]"| [A-Z]$)') AS possible_squad_suffixes
FROM public.opponents WHERE deleted_at IS NULL;

SELECT count(*) AS active_games,
 count(*) FILTER (WHERE payload->>'opponent' ~* '(sub[ -]?[0-9]{1,2}|u[ -]?[0-9]{1,2}|divis[aã]o|s[eé]rie)') AS names_with_age_or_series
FROM public.games WHERE deleted_at IS NULL;

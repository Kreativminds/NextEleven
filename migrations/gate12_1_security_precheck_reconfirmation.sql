-- ============================================================================
-- GATE 12.1 — Priority A: security remediation pre-check, reconfirmed fresh.
-- READ-ONLY. Executed directly against production (wicydcvdakqopodbxtrl).
-- Nothing written. NOT authorized to execute the remediation itself in this
-- prompt -- see "APPROVAL A REQUIRED" below.
-- ============================================================================

-- Direct check, this gate:
--   select count(*) from public.opponents_merge_plan_tmp;                    -> 35
--   select relrowsecurity from pg_class
--     where oid = 'public.opponents_merge_plan_tmp'::regclass;               -> false (RLS disabled)
--   select count(*) from pg_policies
--     where schemaname='public' and tablename='opponents_merge_plan_tmp';    -> 0

-- Cross-checked against Supabase's own security advisor (get_advisors,
-- type=security), run this gate: "RLS Disabled in Public" fires exactly
-- ONCE project-wide, and it is this table. No change since Gate 10.1 /
-- Gate 11.9 -- same 35 rows, same disabled state, same zero policies.

-- Application dependency check (this gate): grepped the full repository
-- (index.html, team.html, public-stats-core.js, css/, tests/, every
-- migrations/*.sql) for "opponents_merge_plan_tmp". It appears ONLY inside
-- this engagement's own migration/report files (its own creation in
-- gate3_merge_plan_tmp_rls_fix.sql, and references in the Gate 9/10/11
-- pre-check and report files). It is never referenced by any live
-- application file, any RPC function, any trigger, or any scheduled job.
-- No application code path reads from or writes to this table. CONFIRMED:
-- no active application dependencies exist.

-- Unrelated pre-existing advisories surfaced by this gate's advisor run
-- (security_definer views, function search_path_mutable, anon/authenticated
-- SECURITY DEFINER RPC exposure, leaked-password-protection disabled,
-- extension_in_public, rls_enabled_no_policy on 5 other tables) are ALL
-- pre-existing, unrelated to opponents_merge_plan_tmp, and explicitly OUT
-- OF SCOPE for this instruction -- not touched, not remediated here.

-- ============================================================================
-- APPROVAL A REQUIRED -- exact statement, not executed by this prompt:
-- ============================================================================
--   ALTER TABLE public.opponents_merge_plan_tmp ENABLE ROW LEVEL SECURITY;
--
-- Stopping here per Gate 12 Priority A instruction: "Stop and request my
-- explicit approval to execute this exact statement in production."
-- Once separately approved, this single statement will be executed alone
-- (not combined with any federation deployment step), and verified
-- immediately after for: RLS enabled, all 35 rows preserved, anonymous and
-- unauthorized authenticated access denied, no unexpected database errors.

select 'Gate 12.1 complete. Pre-check reconfirmed fresh, read-only, production: opponents_merge_plan_tmp has 35 rows, RLS still disabled, 0 policies, no application dependencies (repo-wide grep confirms references only in this engagement''s own migration/report files). Exact Approval A statement restated. NOT executed -- awaiting Victor''s explicit separate approval.' as status;

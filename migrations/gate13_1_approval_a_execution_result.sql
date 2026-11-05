-- ============================================================================
-- GATE 13.1 — APPROVAL A EXECUTED. This is the first production write this
-- entire engagement has made. Executed exactly once, alone, not combined
-- with anything else, per Victor's explicit approval.
-- ============================================================================

-- PRE-CHECK, reconfirmed fresh immediately before execution:
--   project_id: wicydcvdakqopodbxtrl ("Football-tracker") -- CORRECT project
--   select count(*) from public.opponents_merge_plan_tmp;                 -> 35
--   select relrowsecurity from pg_class
--     where oid='public.opponents_merge_plan_tmp'::regclass;              -> false
--   select count(*) from pg_policies
--     where schemaname='public' and tablename='opponents_merge_plan_tmp'; -> 0
--   Repo-wide grep: no application/RPC/trigger/job dependency found.
-- All 4 conditions matched exactly -- proceeded.

-- EXECUTED (exactly this statement, exactly once):
ALTER TABLE public.opponents_merge_plan_tmp ENABLE ROW LEVEL SECURITY;
-- Result: no errors.

-- POST-CHECK, immediately after:
--   relrowsecurity                                                        -> true
--   row count                                                             -> 35 (unchanged)
--   policy count                                                          -> 0 (unchanged -- no policy was created, by design;
--                                                                              RLS + zero policies = default-deny for every role
--                                                                              except the table owner/service_role, which bypasses
--                                                                              RLS entirely, same as every other table in this schema)
--   Direct anon-role test: `set role anon; select count(*) from
--     public.opponents_merge_plan_tmp;` -> 0 rows returned (public/anon
--     access confirmed DENIED)
--   Security advisor re-run: opponents_merge_plan_tmp no longer appears
--     under "RLS Disabled in Public" (that finding is now GONE entirely --
--     0 occurrences project-wide). It now appears once under the benign,
--     INFO-level "RLS Enabled No Policy" finding (count 5 -> 6), exactly
--     the same info-level status as app_meta/backups/portal_change_log/
--     portal_sessions/training_templates_official already carried before
--     this gate -- not a new category of issue, just this table joining a
--     pre-existing, accepted pattern.
--   Every OTHER advisory finding (security_definer views x4, function
--     search_path_mutable x7, anon/authenticated-executable SECURITY
--     DEFINER RPCs x17/x12, extension_in_public x1, leaked-password-
--     protection x1) is byte-identical before and after -- confirmed no
--     other schema or data change occurred.

select 'Gate 13.1 complete. Approval A executed successfully and in isolation: RLS now enabled on public.opponents_merge_plan_tmp, all 35 rows preserved, anon/public access directly tested and confirmed denied, zero other schema or data change. Reported to Victor immediately per his instruction.' as status;

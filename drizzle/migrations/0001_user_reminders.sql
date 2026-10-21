CREATE TABLE public.user_reminders (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  activity_key text NOT NULL,
  remind_at time NOT NULL,
  enabled boolean NOT NULL DEFAULT false,
  weekdays smallint[] NOT NULL DEFAULT '{0,1,2,3,4,5,6}',
  timezone text NOT NULL DEFAULT 'Africa/Cairo',
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (user_id, activity_key),
  CHECK (activity_key IN ('morning_prayer','sunset_prayer','bible_reading','night_prayer','wake_up','school_start','school_return','commute','work','study_start','study_end','meal','sleep')),
  CHECK (weekdays <@ '{0,1,2,3,4,5,6}'::smallint[])
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.user_reminders TO authenticated;
GRANT ALL ON public.user_reminders TO service_role;
ALTER TABLE public.user_reminders ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Own reminders read" ON public.user_reminders FOR SELECT TO authenticated USING (auth.uid() = user_id);
CREATE POLICY "Own reminders insert" ON public.user_reminders FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Own reminders update" ON public.user_reminders FOR UPDATE TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Own reminders delete" ON public.user_reminders FOR DELETE TO authenticated USING (auth.uid() = user_id);

-- Saves all reminders and marks setup complete in one transaction, as the calling user (RLS applies).
CREATE OR REPLACE FUNCTION public.save_my_schedule(_items jsonb, _timezone text)
RETURNS void LANGUAGE plpgsql SECURITY INVOKER SET search_path = public AS $$
DECLARE uid uuid := auth.uid(); it jsonb;
BEGIN
  IF uid IS NULL THEN RAISE EXCEPTION 'not authenticated'; END IF;
  FOR it IN SELECT * FROM jsonb_array_elements(_items) LOOP
    INSERT INTO public.user_reminders (user_id, activity_key, remind_at, enabled, weekdays, timezone, updated_at)
    VALUES (uid, it->>'key', (it->>'time')::time, (it->>'enabled')::boolean,
      ARRAY(SELECT jsonb_array_elements_text(it->'days')::smallint), _timezone, now())
    ON CONFLICT (user_id, activity_key) DO UPDATE SET remind_at = EXCLUDED.remind_at, enabled = EXCLUDED.enabled,
      weekdays = EXCLUDED.weekdays, timezone = EXCLUDED.timezone, updated_at = now();
  END LOOP;
  UPDATE public.profiles SET schedule_completed = true WHERE id = uid;
END $$;
REVOKE ALL ON FUNCTION public.save_my_schedule(jsonb, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.save_my_schedule(jsonb, text) TO authenticated;
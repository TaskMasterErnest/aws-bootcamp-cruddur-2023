-- this file was manually created (because we might auto generate it in future)
INSERT INTO public.users (display_name, email, handle, cognito_user_id)
VALUES
  ('Ernest', 'kluernest08@gmail.com', 'Ernest', 'MOCK'),
  ('Taskmaster', 'woeliernest@gmail.com', 'taskmaster' ,'MOCK'),
  ('Londo Mollari', 'lmollari@centauri.com', 'londo', 'MOCK');

INSERT INTO public.activities (user_uuid, message, expires_at)
VALUES
  (
    (SELECT uuid from public.users WHERE users.handle = 'Ernest' LIMIT 1),
    'This was imported as seed data!',
    current_timestamp + interval '10 day'
  )
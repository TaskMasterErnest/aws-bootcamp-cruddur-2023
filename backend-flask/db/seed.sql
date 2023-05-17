-- this file was manually created (because we might auto generate it in future)
INSERT INTO public.users (display_name, email, handle, cognito_user_id)
VALUES
  ('Ernest', 'kluernest08@gmail.com', 'Ernest', '4b45093d-1bdd-411a-b7fa-4b779eddf7ae'),
  ('Taskmaster', 'woeliernest@gmail.com', 'taskmaster' ,'82d183eb-1cff-4651-8753-9d038802cb75'),
  ('Londo Mollari', 'lmollari@centauri.com', 'londo', 'MOCK');

INSERT INTO public.activities (user_uuid, message, expires_at)
VALUES
  (
    (SELECT uuid from public.users WHERE users.handle = 'Ernest' LIMIT 1),
    'This was imported as seed data!',
    current_timestamp + interval '10 day'
  )
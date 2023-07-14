-- this file was manually created (because we might auto generate it in future)
INSERT INTO public.users (display_name, email, handle, cognito_user_id)
VALUES
  ('The Taskmaster', 'kluernest08@gmail.com', 'thetaskmaster' ,'9f1f224b-a215-45e6-8476-206965f90261'),
  ('Londo Mollari','lmollari@centari.com' ,'londo' ,'MOCK'),
  ('Alt Taskmaster', 'woeliernest@gmail.com', 'altmaster' ,'MOCK');

INSERT INTO public.activities (user_uuid, message, expires_at)
VALUES
  (
    (SELECT uuid from public.users WHERE users.handle = 'thetaskmaster' LIMIT 1),
    'This was imported as seed data!',
    current_timestamp + interval '10 day'
  ),
  (
    (SELECT uuid from public.users WHERE users.handle = 'altmaster' LIMIT 1),
    'I am the other seed data!',
    current_timestamp + interval '10 day'
  );
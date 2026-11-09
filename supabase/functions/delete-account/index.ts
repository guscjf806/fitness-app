// 동의를 거절한 회원의 로그인 계정을 지운다 (결정 d1105-2).
// 로그인한 본인 계정만 지울 수 있다. 개인정보는 로그에 남기지 않는다.
// 회원 정보 표(profiles 등)를 만들면 그 표의 행도 여기서 함께 지운다.
import { createClient } from 'npm:@supabase/supabase-js@2';

Deno.serve(async (req: Request) => {
  if (req.method !== 'POST') return new Response('method not allowed', { status: 405 });
  const jwt = (req.headers.get('Authorization') ?? '').replace(/^Bearer\s+/i, '');
  if (!jwt) return new Response('unauthorized', { status: 401 });

  const admin = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const { data, error } = await admin.auth.getUser(jwt);
  if (error || !data.user) return new Response('unauthorized', { status: 401 });

  const { error: deleteError } = await admin.auth.admin.deleteUser(data.user.id);
  if (deleteError) return new Response('failed', { status: 500 });

  return new Response(JSON.stringify({ deleted: true }), { headers: { 'Content-Type': 'application/json' } });
});

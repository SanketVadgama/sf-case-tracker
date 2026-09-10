import express from 'express';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const app = express();
const PORT = 3000;

app.use(express.json());
app.use(express.static(__dirname));

const SUPABASE_URL = process.env.SUPABASE_URL || 'https://janazasbsaykpljsijnf.supabase.co';
const SUPABASE_ANON_KEY = process.env.SUPABASE_ANON_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImphbmF6YXNic2F5a3BsanNpam5mIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODc4NDk4MTMsImV4cCI6MjEwMzQyNTgxM30.psjefBp2K2uS4hq7mXeAVtYS8wULEL3oqsVX9HTNXG8';

// Public non-sensitive Supabase client configuration
app.get('/api/config', (req, res) => {
  res.json({
    supabaseUrl: SUPABASE_URL,
    supabaseAnonKey: SUPABASE_ANON_KEY
  });
});

// Admin User Invite endpoint (uses SUPABASE_SERVICE_ROLE_KEY if set, or returns guidance)
app.post('/api/admin/invite', async (req, res) => {
  const { email, name, role } = req.body || {};
  if (!email) {
    return res.status(400).json({ error: 'Email is required' });
  }

  const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
  if (!serviceRoleKey) {
    return res.status(501).json({
      error: 'SUPABASE_SERVICE_ROLE_KEY is not configured on the server.',
      manualRequired: true
    });
  }

  try {
    const inviteRes = await fetch(`${SUPABASE_URL}/auth/v1/invite`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'apikey': serviceRoleKey,
        'Authorization': `Bearer ${serviceRoleKey}`
      },
      body: JSON.stringify({
        email,
        data: { name: name || email.split('@')[0], role: role || 'employee' }
      })
    });

    const inviteData = await inviteRes.json();
    if (!inviteRes.ok) {
      return res.status(inviteRes.status).json({ error: inviteData.msg || inviteData.message || 'Failed to send invite' });
    }

    // Upsert into public.profiles
    if (inviteData?.id) {
      await fetch(`${SUPABASE_URL}/rest/v1/profiles`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'apikey': serviceRoleKey,
          'Authorization': `Bearer ${serviceRoleKey}`,
          'Prefer': 'resolution=merge-duplicates'
        },
        body: JSON.stringify({
          id: inviteData.id,
          email,
          name: name || email.split('@')[0],
          role: role || 'employee'
        })
      });
    }

    return res.json({ success: true, user: inviteData });
  } catch (err) {
    return res.status(500).json({ error: err.message || 'Server error inviting user' });
  }
});

// Admin Update User Role endpoint (bypasses client-side RLS when service role key is present)
app.post('/api/admin/set-role', async (req, res) => {
  const { userId, role } = req.body || {};
  if (!userId || !role) {
    return res.status(400).json({ error: 'userId and role are required' });
  }

  const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
  if (!serviceRoleKey) {
    return res.status(501).json({
      error: 'SUPABASE_SERVICE_ROLE_KEY not configured on server',
      manualRequired: true
    });
  }

  try {
    const updateRes = await fetch(`${SUPABASE_URL}/rest/v1/profiles?id=eq.${userId}`, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'apikey': serviceRoleKey,
        'Authorization': `Bearer ${serviceRoleKey}`,
        'Prefer': 'return=representation'
      },
      body: JSON.stringify({ role, updated_at: new Date().toISOString() })
    });

    const data = await updateRes.json();
    if (!updateRes.ok) {
      return res.status(updateRes.status).json({ error: data.message || 'Failed to update profile' });
    }

    // Also update auth.users metadata if possible so both stay in sync
    try {
      await fetch(`${SUPABASE_URL}/auth/v1/admin/users/${userId}`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
          'apikey': serviceRoleKey,
          'Authorization': `Bearer ${serviceRoleKey}`
        },
        body: JSON.stringify({ user_metadata: { role } })
      });
    } catch(e) {}

    return res.json({ success: true, profile: data });
  } catch(err) {
    return res.status(500).json({ error: err.message || 'Server error updating role' });
  }
});

app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, 'index.html'));
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`SF Case Tracker running on http://0.0.0.0:${PORT}`);
});

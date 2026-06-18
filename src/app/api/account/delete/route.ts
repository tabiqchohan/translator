import { auth } from '@/auth';
import { deleteUser } from '@/lib/auth-db';
import { deleteUserTranslations } from '@/lib/db';
import { findUserByEmail } from '@/lib/auth-db';
import bcrypt from 'bcryptjs';

export async function POST(request: Request) {
  try {
    const session = await auth();
    if (!session?.user?.id) {
      return Response.json({ error: 'Not authenticated' }, { status: 401 });
    }

    const { password } = await request.json();
    if (!password) {
      return Response.json({ error: 'Password is required' }, { status: 400 });
    }

    const user = await findUserByEmail(session.user.email ?? '');
    if (!user) {
      return Response.json({ error: 'User not found' }, { status: 404 });
    }

    const isValid = await bcrypt.compare(password, user.password_hash);
    if (!isValid) {
      return Response.json({ error: 'Incorrect password' }, { status: 403 });
    }

    await deleteUserTranslations(session.user.id);
    await deleteUser(session.user.id);

    return Response.json({ success: true });
  } catch {
    return Response.json({ error: 'Failed to delete account' }, { status: 500 });
  }
}

import { NextRequest, NextResponse } from 'next/server';
import bcrypt from 'bcryptjs';
import { findVerificationToken, deleteVerificationToken, findUserByEmail, updatePassword } from '@/lib/auth-db';

export async function POST(request: NextRequest) {
  try {
    const { email, token, password } = await request.json();

    if (!email || !token || !password) {
      return NextResponse.json({ error: 'Email, token, and password are required' }, { status: 400 });
    }

    if (password.length < 6) {
      return NextResponse.json({ error: 'Password must be at least 6 characters' }, { status: 400 });
    }

    const stored = await findVerificationToken(email.toLowerCase(), token);
    if (!stored) {
      return NextResponse.json({ error: 'Invalid or expired reset token' }, { status: 400 });
    }

    if (new Date(stored.expires) < new Date()) {
      return NextResponse.json({ error: 'Reset token has expired' }, { status: 400 });
    }

    const passwordHash = await bcrypt.hash(password, 12);
    await updatePassword(email.toLowerCase(), passwordHash);
    await deleteVerificationToken(email.toLowerCase(), token);

    return NextResponse.json({ message: 'Password updated successfully' });
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unknown error';
    return NextResponse.json({ error: message }, { status: 500 });
  }
}

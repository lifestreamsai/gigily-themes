
Gigily Teams Dark
// Gigily Themes - TypeScript Showcase
import { useState, useEffect } from 'react';

interface User {
  id: number;
  name: string;
  email: string;
  role: 'admin' | 'user' | 'guest';
}

type AsyncResult<T> = Promise<{ data: T; error?: string }>;

/**
 * Fetches user data from the API
 * @param userId - The unique user identifier
 * @returns User object or null if not found
 */
async function fetchUser(userId: number): AsyncResult<User | null> {
  const API_URL = 'https://api.example.com';

  try {
    const response = await fetch(`${API_URL}/users/${userId}`);

    if (!response.ok) {
      throw new Error(`HTTP ${response.status}`);
    }

    const user: User = await response.json();
    return { data: user };
  } catch (error) {
    console.error('Failed to fetch user:', error);
    return { data: null, error: String(error) };
  }
}

// React component with hooks
function UserProfile({ userId }: { userId: number }) {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchUser(userId).then(({ data }) => {
      setUser(data);
      setLoading(false);
    });
  }, [userId]);

  if (loading) return <div>Loading...</div>;
  if (!user) return <div>User not found</div>;

  const isAdmin = user.role === 'admin';
  const greeting = `Hello, ${user.name}!`;

  return (
    <div className={isAdmin ? 'admin-profile' : 'user-profile'}>
      <h1>{greeting}</h1>
      <p>Email: {user.email}</p>
      <span>Role: {user.role.toUpperCase()}</span>
    </div>
  );
}

// Utility functions
const formatDate = (date: Date): string => {
  return date.toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'long',
    day: 'numeric'
  });
};

const numbers = [1, 2, 3, 4, 5];
const doubled = numbers.map(n => n * 2);
const sum = numbers.reduce((acc, n) => acc + n, 0);

export { fetchUser, UserProfile, formatDate };

import { useState } from 'react';
import { Lock, User, ShieldAlert, Cpu } from 'lucide-react';
import { apiFetch } from './api';

export default function LoginScreen({ onLoginSuccess }) {
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');
    setLoading(true);

    try {
      const response = await apiFetch('/api/auth/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ username, password })
      });

      if (!response.ok) {
        throw new Error('Access Denied. Check credentials.');
      }

      const data = await response.json();
      if (data.access_token) {
        onLoginSuccess(data.access_token);
      }
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="login-wrapper">
      <div className="glass-panel login-card">
        <div className="login-header">
          <img src="/logo.jpg" alt="GhostNodes Logo" className="login-logo-img" />
          <h2>Ghost Nodes</h2>
          <p>Sovereign Access Control</p>
        </div>

        <form onSubmit={handleSubmit} className="login-form">
          {error && (
            <div className="login-error">
              <ShieldAlert size={18} />
              <span>{error}</span>
            </div>
          )}

          <div className="input-group">
            <User className="input-icon" size={20} />
            <input 
              type="text" 
              placeholder="System Username"
              value={username}
              onChange={(e) => setUsername(e.target.value)}
              required
              disabled={loading}
              autoComplete="username"
            />
          </div>

          <div className="input-group">
            <Lock className="input-icon" size={20} />
            <input 
              type="password" 
              placeholder="System Password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              required
              disabled={loading}
              autoComplete="current-password"
            />
          </div>

          <button type="submit" className="login-button" disabled={loading || !username || !password}>
            {loading ? 'Authenticating...' : 'Unlock Node'}
          </button>
        </form>
      </div>
    </div>
  );
}

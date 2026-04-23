import { useEffect, useState } from 'react';
import { motion } from 'framer-motion';
import { Globe, Shield, Box, Terminal, RefreshCw } from 'lucide-react';
import { apiFetch } from './api';

const iconMap = {
  shield: Shield,
  box: Box,
  terminal: Terminal,
  'refresh-cw': RefreshCw,
};

export default function ApplicationsTab({ token }) {
  const [apps, setApps] = useState([]);
  const [error, setError] = useState('');

  useEffect(() => {
    const fetchApps = async () => {
      try {
        const res = await apiFetch('/api/system/apps', {
          headers: { Authorization: `Bearer ${token}` },
        });
        if (!res.ok) {
          throw new Error(await res.text());
        }
        setApps(await res.json());
      } catch (err) {
        setError(err.message);
      }
    };

    fetchApps();
  }, [token]);

  if (error) {
    return (
      <div className="glass-panel" style={{ padding: '1.5rem', color: 'var(--danger)' }}>
        Applications unavailable: {error}
      </div>
    );
  }

  return (
    <section style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(240px, 1fr))', gap: '1rem' }}>
      {apps.map((app) => {
        const Icon = iconMap[app.icon] || Globe;
        const href = app.url_path.startsWith(':')
          ? `${window.location.protocol}//${window.location.hostname}${app.url_path}`
          : `${window.location.origin}${app.url_path}`;

        return (
          <motion.a
            key={app.id}
            href={href}
            target="_blank"
            rel="noreferrer"
            className="glass-panel"
            style={{ padding: '1.25rem', textDecoration: 'none', color: 'inherit', display: 'block' }}
            initial={{ opacity: 0, y: 16 }}
            animate={{ opacity: 1, y: 0 }}
          >
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '0.75rem' }}>
              <Icon size={20} color="var(--accent-glow)" />
              <span style={{ color: app.status === 'online' ? 'var(--success)' : 'var(--text-dim)', fontSize: '0.8rem' }}>
                {app.status}
              </span>
            </div>
            <h3 style={{ margin: 0, marginBottom: '0.5rem', fontSize: '1rem' }}>{app.name}</h3>
            <p className="text-dim" style={{ margin: 0, fontSize: '0.9rem', lineHeight: 1.5 }}>
              {app.description}
            </p>
          </motion.a>
        );
      })}
    </section>
  );
}

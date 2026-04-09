import React, { useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import { ExternalLink, Box, Activity, Shield, RefreshCw, Cpu, Database, Settings, Layout } from 'lucide-react';

const APP_ASSETS = {
  cockpit: "https://cockpit-project.org/images/cockpit-logo-white.svg",
  pihole: "https://pi-hole.net/assets/img/logo/logo-blue.svg",
  syncthing: "https://syncthing.net/img/logo-horizontal.svg",
  portainer: "https://www.portainer.io/hubfs/Portainer%20Logo%202021.svg",
  hendal: "https://raw.githubusercontent.com/k3zeus/GhostNodes/beta/assets/logo.png"
};

export default function ApplicationsTab({ token }) {
  const [apps, setApps] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchApps = async () => {
      try {
        const res = await fetch('http://localhost:8000/api/system/apps', {
          headers: { 'Authorization': `Bearer ${token}` }
        });
        if (res.ok) {
          setApps(await res.json());
        }
      } catch (err) {
        console.error("Failed to fetch apps", err);
      } finally {
        setLoading(false);
      }
    };
    fetchApps();
  }, [token]);

  const getIcon = (iconName) => {
    switch(iconName) {
      case 'shield': return <Shield size={24} />;
      case 'activity': return <Activity size={24} />;
      case 'refresh-cw': return <RefreshCw size={24} />;
      case 'box': return <Box size={24} />;
      case 'layout': return <Layout size={24} />;
      default: return <Cpu size={24} />;
    }
  };

  return (
    <motion.div initial={{ opacity: 0, scale: 0.98 }} animate={{ opacity: 1, scale: 1 }} style={{ padding: '0.5rem' }}>
      <header style={{ marginBottom: '2rem' }}>
        <h2 className="gradient-text" style={{ fontSize: '1.8rem', fontWeight: 700, margin: 0 }}>Ghost Applications</h2>
        <p className="text-dim">External tools and containers managed by your node.</p>
      </header>

      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(320px, 1fr))', gap: '1.5rem' }}>
        {loading ? (
          <div className="glass-panel" style={{ padding: '3rem', textAlign: 'center', gridColumn: '1 / -1' }}>
            <RefreshCw className="text-dim animate-spin" size={48} style={{ marginBottom: '1rem', opacity: 0.3, margin: '0 auto' }} />
            <p className="text-dim">Detecting installed services...</p>
          </div>
        ) : apps.length === 0 ? (
          <div className="glass-panel" style={{ padding: '3rem', textAlign: 'center', gridColumn: '1 / -1' }}>
            <Box className="text-dim" size={48} style={{ marginBottom: '1rem', opacity: 0.3, margin: '0 auto' }} />
            <p className="text-dim">No specialized apps found.</p>
          </div>
        ) : (
          apps.map((app) => (
            <motion.div 
              key={app.id} 
              className="glass-panel" 
              whileHover={{ y: -5, boxShadow: '0 12px 40px rgba(0,0,0,0.3)' }}
              style={{ 
                padding: '0', 
                overflow: 'hidden', 
                position: 'relative',
                display: 'flex',
                flexDirection: 'column',
                minHeight: '220px',
                border: '1px solid rgba(255,255,255,0.05)',
                background: 'rgba(20, 20, 20, 0.4)'
              }}
            >
              <div style={{ 
                position: 'absolute', 
                top: '-10%', 
                right: '-10%', 
                width: '160px', 
                height: '160px', 
                backgroundImage: `url(${APP_ASSETS[app.id] || APP_ASSETS.hendal})`,
                backgroundSize: 'contain',
                backgroundPosition: 'center',
                backgroundRepeat: 'no-repeat',
                filter: 'blur(25px) opacity(0.15)',
                zIndex: 0
              }} />

              <div style={{ padding: '1.5rem', flex: 1, position: 'relative', zIndex: 1, display: 'flex', flexDirection: 'column' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '1rem' }}>
                  <div style={{ background: 'rgba(255,255,255,0.05)', padding: '0.8rem', borderRadius: '12px', border: '1px solid rgba(255,255,255,0.1)', color: 'var(--accent-glow)' }}>
                    {getIcon(app.icon)}
                  </div>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', background: 'rgba(0,0,0,0.2)', padding: '4px 8px', borderRadius: '20px' }}>
                    <div style={{ width: 6, height: 6, borderRadius: '50%', background: app.status === 'online' ? 'var(--success)' : 'var(--danger)' }} />
                    <span style={{ fontSize: '0.65rem', fontWeight: 800, textTransform: 'uppercase', color: app.status === 'online' ? 'var(--success)' : 'var(--danger)' }}>
                      {app.status}
                    </span>
                  </div>
                </div>

                <h3 style={{ margin: '0 0 0.5rem 0', fontSize: '1.4rem', fontWeight: 800, color: '#fff' }}>{app.name}</h3>
                <p className="text-dim" style={{ fontSize: '0.85rem', marginBottom: '1.5rem', flex: 1, lineHeight: 1.5 }}>{app.description}</p>

                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', paddingTop: '1.2rem', borderTop: '1px solid rgba(255,255,255,0.08)' }}>
                  <div style={{ display: 'flex', flexDirection: 'column' }}>
                    <span style={{ fontSize: '0.6rem', color: 'var(--text-dim)', textTransform: 'uppercase' }}>Port Binding</span>
                    <span style={{ fontSize: '0.8rem', fontFamily: 'monospace', color: 'var(--accent-glow)', fontWeight: 600 }}>
                      {app.port}
                    </span>
                  </div>
                  <button 
                    onClick={() => {
                        const url = app.url_path.startsWith('/') ? `http://${window.location.hostname}${app.url_path}` : `http://${window.location.hostname}:${app.port}${app.url_path}`;
                        window.open(url, '_blank');
                    }}
                    style={{ 
                      background: 'var(--accent-base)', 
                      color: 'white', 
                      border: 'none', 
                      padding: '0.6rem 1.2rem', 
                      borderRadius: '8px',
                      display: 'flex',
                      alignItems: 'center',
                      gap: '0.5rem',
                      fontSize: '0.85rem',
                      fontWeight: 700,
                      cursor: 'pointer',
                      transition: 'all 0.2s',
                      boxShadow: '0 4px 15px rgba(10,191,159,0.2)'
                    }}
                  >
                    Launch <ExternalLink size={14} />
                  </button>
                </div>
              </div>
            </motion.div>
          ))
        )}
      </div>
    </motion.div>
  );
}

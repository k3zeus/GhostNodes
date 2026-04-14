import { useState, useEffect } from 'react'
import { motion } from 'framer-motion'
import { ExternalLink, Terminal, Shield, RefreshCw, Box, Loader2 } from 'lucide-react'

const ICON_MAP = {
  terminal: Terminal,
  shield: Shield,
  'refresh-cw': RefreshCw,
  box: Box,
}

function ApplicationsTab({ token }) {
  const [apps, setApps] = useState([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    const fetchApps = async () => {
      try {
        const res = await fetch('http://localhost:8000/api/system/apps', {
          headers: { 'Authorization': `Bearer ${token}` }
        })
        if (res.ok) {
          setApps(await res.json())
        }
      } catch (err) {
        console.error('Failed to fetch apps:', err)
      } finally {
        setLoading(false)
      }
    }
    fetchApps()
    const intv = setInterval(fetchApps, 10000)
    return () => clearInterval(intv)
  }, [token])

  if (loading) {
    return (
      <div className="glass-panel" style={{ padding: '3rem', textAlign: 'center' }}>
        <Loader2 size={32} className="text-dim" style={{ animation: 'spin 1s linear infinite' }} />
        <p className="text-dim" style={{ marginTop: '1rem' }}>Loading applications...</p>
      </div>
    )
  }

  return (
    <div>
      <h2 style={{ fontSize: '1.4rem', fontWeight: 700, marginBottom: '1.5rem', display: 'flex', alignItems: 'center', gap: '0.8rem' }}>
        <Box size={22} color="var(--accent-glow)" /> Applications
      </h2>

      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(280px, 1fr))', gap: '1.2rem' }}>
        {apps.map((app, i) => {
          const IconComponent = ICON_MAP[app.icon] || Box
          const isOnline = app.status === 'online'

          return (
            <motion.div
              key={app.id}
              className="glass-panel"
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: i * 0.08 }}
              style={{
                padding: '1.5rem',
                display: 'flex',
                flexDirection: 'column',
                gap: '1rem',
                position: 'relative',
                overflow: 'hidden',
              }}
            >
              {/* Status indicator */}
              <div style={{
                position: 'absolute', top: 12, right: 12,
                width: 10, height: 10, borderRadius: '50%',
                background: isOnline ? 'var(--success)' : 'var(--text-dim)',
                boxShadow: isOnline ? '0 0 8px var(--success)' : 'none',
              }} />

              <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
                <div style={{
                  background: 'rgba(128,128,128,0.1)',
                  padding: '0.8rem',
                  borderRadius: '12px',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                }}>
                  <IconComponent size={28} color={isOnline ? 'var(--accent-glow)' : 'var(--text-dim)'} />
                </div>
                <div>
                  <h3 style={{ fontSize: '1.1rem', fontWeight: 600, margin: 0 }}>{app.name}</h3>
                  <p className="text-dim" style={{ fontSize: '0.75rem', margin: 0 }}>{app.description}</p>
                </div>
              </div>

              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginTop: 'auto' }}>
                <span className="text-dim" style={{ fontSize: '0.7rem', textTransform: 'uppercase' }}>
                  Port {app.port} — {isOnline ? 'Online' : 'Offline'}
                </span>
                {isOnline && (
                  <a
                    href={`${window.location.protocol}//${window.location.hostname}${app.url_path}`}
                    target="_blank"
                    rel="noopener noreferrer"
                    style={{
                      display: 'flex', alignItems: 'center', gap: '4px',
                      color: 'var(--accent-glow)',
                      fontSize: '0.8rem',
                      textDecoration: 'none',
                    }}
                  >
                    Open <ExternalLink size={14} />
                  </a>
                )}
              </div>
            </motion.div>
          )
        })}
      </div>

      {apps.length === 0 && (
        <div className="glass-panel" style={{ padding: '2rem', textAlign: 'center' }}>
          <p className="text-dim">No applications detected on this node.</p>
        </div>
      )}
    </div>
  )
}

export default ApplicationsTab

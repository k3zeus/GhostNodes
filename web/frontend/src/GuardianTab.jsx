import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Shield, ShieldAlert, Lock, Eye, Activity, Terminal, AlertTriangle, Fingerprint, Map, Users, X, Download } from 'lucide-react';

export default function GuardianTab() {
  const [logs, setLogs] = useState([
    { id: 101, time: '01:22:15', origin: '185.220.101.44', action: 'Port Scan Detected', port: '80, 443, 8080', severity: 'low' },
    { id: 102, time: '01:25:30', origin: '45.155.205.12', action: 'Brute Force Attempt', port: '22 (SSH)', severity: 'high' },
    { id: 103, time: '01:30:02', origin: '192.168.1.1', action: 'Internal Integrity Check', port: 'SYSTEM', severity: 'success' }
  ]);

  const [attackers, setAttackers] = useState([
    { ip: '185.220.101.44', country: 'Germany', attempts: 42, lastSeen: '04:12', risk: 'Medium' },
    { ip: '45.155.205.12', country: 'Russia', attempts: 156, lastSeen: '04:15', risk: 'Critical' },
    { ip: '103.44.2.19', country: 'China', attempts: 89, lastSeen: '03:55', risk: 'High' },
    { ip: '5.188.62.99', country: 'Netherlands', attempts: 210, lastSeen: '04:18', risk: 'Critical' }
  ]);

  const [sshAlert, setSshAlert] = useState(true);
  const [showReport, setShowReport] = useState(false);

  // Simulação de logs em tempo real
  useEffect(() => {
    const interval = setInterval(() => {
        const brands = ['92.10.33.1', '103.44.2.19', '5.188.62.99', '178.128.90.5'];
        const actions = ['SSH Auth Failure', 'GET /wp-admin', 'SYN Flood Rejected', 'SMTP Relay Attempt'];
        
        const newLog = {
            id: Date.now(),
            time: new Date().toLocaleTimeString(),
            origin: brands[Math.floor(Math.random() * brands.length)],
            action: actions[Math.floor(Math.random() * actions.length)],
            port: Math.random() > 0.5 ? '22' : '445',
            severity: Math.random() > 0.7 ? 'high' : 'low'
        };

        setLogs(prev => [newLog, ...prev.slice(0, 7)]);
        if (newLog.port === '22') setSshAlert(true);
    }, 5000);

    return () => clearInterval(interval);
  }, []);

  return (
    <motion.div initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} style={{ display: 'flex', flexDirection: 'column', gap: '2rem' }}>
      
      {/* Dynamic Alert Banner */}
      <AnimatePresence>
        {sshAlert && (
          <motion.div 
            initial={{ height: 0, opacity: 0 }}
            animate={{ height: 'auto', opacity: 1 }}
            exit={{ height: 0, opacity: 0 }}
            style={{ 
                background: 'rgba(255, 68, 68, 0.15)', 
                border: '1px solid rgba(255, 68, 68, 0.3)', 
                borderRadius: '12px', 
                padding: '1rem',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'space-between',
                color: '#ff4444'
            }}
          >
            <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
                <AlertTriangle size={24} />
                <div>
                    <strong style={{ display: 'block' }}>SSH ATTACK MITIGATED</strong>
                    <span style={{ fontSize: '0.85rem', opacity: 0.8 }}>O HoneyPot Docker interceptou uma tentativa de login na porta 22.</span>
                </div>
            </div>
            <button onClick={() => setSshAlert(false)} style={{ background: 'none', border: '1px solid #ff4444', color: '#ff4444', padding: '4px 12px', borderRadius: '4px', cursor: 'pointer' }}>Dismiss</button>
          </motion.div>
        )}
      </AnimatePresence>

      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(280px, 1fr))', gap: '1.5rem' }}>
        <div className="glass-panel" style={{ padding: '1.5rem', display: 'flex', gap: '1.5rem', background: 'linear-gradient(135deg, rgba(10,191,159,0.1) 0%, rgba(0,0,0,0.2) 100%)' }}>
          <Shield size={40} color="var(--accent-glow)" />
          <div>
            <h3 style={{ margin: 0, fontSize: '1.2rem' }}>Sovereign Shield</h3>
            <p className="text-dim" style={{ fontSize: '0.85rem' }}>Active Protection: <strong>Docker Honeypot</strong></p>
          </div>
        </div>

        <div className="glass-panel" style={{ padding: '1.5rem', display: 'flex', gap: '1.5rem' }}>
          <Fingerprint size={40} color="var(--warning)" />
          <div>
            <h3 style={{ margin: 0, fontSize: '1.2rem' }}>Identity Guard</h3>
            <p className="text-dim" style={{ fontSize: '0.85rem' }}>0 Chaves expostas publicamente.</p>
          </div>
        </div>

        <motion.div 
          onClick={() => setShowReport(true)}
          whileHover={{ scale: 1.02, cursor: 'pointer' }}
          className="glass-panel" 
          style={{ padding: '1.5rem', display: 'flex', gap: '1.5rem', border: '1px solid rgba(255,68,68,0.2)' }}
        >
          <Users size={40} color="var(--danger)" />
          <div>
            <h3 style={{ margin: 0, fontSize: '1.2rem' }}>Identify Attackers</h3>
            <p className="text-dim" style={{ fontSize: '0.85rem' }}><strong>{attackers.length} Invaders</strong> detected. Click for report.</p>
          </div>
        </motion.div>
      </div>

      {/* HoneyPot Real-time Logs */}
      <div className="glass-panel" style={{ padding: '0', overflow: 'hidden', background: '#0a0a0a' }}>
        <div style={{ padding: '1rem 1.5rem', borderBottom: '1px solid rgba(255,255,255,0.05)', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <h2 style={{ fontSize: '1rem', display: 'flex', alignItems: 'center', gap: '0.6rem', margin: 0 }}>
                <Terminal size={18} color="var(--accent-glow)" /> HoneyPot Live Defense Logs
            </h2>
            <div style={{ fontSize: '0.7rem', color: 'var(--success)', display: 'flex', alignItems: 'center', gap: '6px' }}>
                <div style={{ width: 6, height: 6, borderRadius: '50%', background: 'var(--success)', boxShadow: '0 0 5px var(--success)' }} />
                REAL-TIME MONITORING
            </div>
        </div>
        
        <div style={{ padding: '1rem', maxHeight: '400px', overflowY: 'auto', fontFamily: 'monospace', fontSize: '0.85rem' }}>
            <table style={{ width: '100%', borderCollapse: 'collapse' }}>
                <thead>
                    <tr style={{ color: 'rgba(255,255,255,0.3)', textAlign: 'left', borderBottom: '1px solid rgba(255,255,255,0.05)' }}>
                        <th style={{ padding: '0.5rem' }}>TIME</th>
                        <th style={{ padding: '0.5rem' }}>ORIGIN IP</th>
                        <th style={{ padding: '0.5rem' }}>EVENT</th>
                        <th style={{ padding: '0.5rem' }}>TARGET</th>
                        <th style={{ padding: '0.5rem' }}>STATUS</th>
                    </tr>
                </thead>
                <tbody>
                    {logs.map((log) => (
                        <motion.tr 
                          initial={{ opacity: 0, x: -10 }} 
                          animate={{ opacity: 1, x: 0 }}
                          key={log.id} 
                          style={{ borderBottom: '1px solid rgba(255,255,255,0.02)', color: log.severity === 'high' ? '#ff4444' : '#eee' }}
                        >
                            <td style={{ padding: '0.8rem', opacity: 0.5 }}>{log.time}</td>
                            <td style={{ padding: '0.8rem', fontWeight: 600 }}>{log.origin}</td>
                            <td style={{ padding: '0.8rem' }}>{log.action}</td>
                            <td style={{ padding: '0.8rem', color: 'var(--accent-glow)' }}>{log.port}</td>
                            <td style={{ padding: '0.8rem' }}>
                                <span style={{ 
                                    padding: '2px 6px', 
                                    borderRadius: '4px', 
                                    fontSize: '0.7rem', 
                                    background: log.severity === 'high' ? 'rgba(255,68,68,0.2)' : 'rgba(10,191,159,0.1)',
                                    color: log.severity === 'high' ? '#ff4444' : 'var(--accent-glow)'
                                }}>
                                    {log.severity === 'high' ? 'BLOCKED' : 'LOGGED'}
                                </span>
                            </td>
                        </motion.tr>
                    ))}
                </tbody>
            </table>
        </div>
      </div>

      {/* Attacker Report Modal */}
      <AnimatePresence>
        {showReport && (
          <motion.div 
            initial={{ opacity: 0 }} 
            animate={{ opacity: 1 }} 
            exit={{ opacity: 0 }}
            style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.85)', zIndex: 2000, display: 'flex', alignItems: 'center', justifyContent: 'center', padding: '2rem' }}
          >
            <motion.div 
               initial={{ scale: 0.9, y: 20 }} 
               animate={{ scale: 1, y: 0 }} 
               className="glass-panel" 
               style={{ width: '100%', maxWidth: '800px', maxHeight: '80vh', overflow: 'hidden', display: 'flex', flexDirection: 'column', border: '1px solid rgba(255,255,255,0.1)' }}
            >
                <div style={{ padding: '1.5rem', borderBottom: '1px solid rgba(255,255,255,0.05)', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                    <div>
                        <h2 style={{ margin: 0, fontSize: '1.5rem', display: 'flex', alignItems: 'center', gap: '10px' }}>
                            <AlertTriangle color="var(--danger)" /> Attacker Identity Report
                        </h2>
                        <p className="text-dim" style={{ fontSize: '0.85rem' }}>Detailed analysis of persistent intruders found by the Honeypot.</p>
                    </div>
                    <button onClick={() => setShowReport(false)} style={{ background: 'rgba(255,255,255,0.05)', border: 'none', color: 'white', padding: '8px', borderRadius: '50%', cursor: 'pointer' }}>
                        <X size={20} />
                    </button>
                </div>

                <div style={{ flex: 1, overflowY: 'auto', padding: '1.5rem' }}>
                    <table style={{ width: '100%', borderCollapse: 'collapse' }}>
                        <thead>
                            <tr style={{ textAlign: 'left', color: 'var(--text-dim)', borderBottom: '2px solid rgba(255,255,255,0.05)' }}>
                                <th style={{ padding: '1rem' }}>IP ADDRESS</th>
                                <th style={{ padding: '1rem' }}>LOCATION</th>
                                <th style={{ padding: '1rem' }}>ATTEMPTS</th>
                                <th style={{ padding: '1rem' }}>RISK LEVEL</th>
                                <th style={{ padding: '1rem' }}>LAST SEEN</th>
                            </tr>
                        </thead>
                        <tbody>
                            {attackers.map((att, idx) => (
                                <tr key={idx} style={{ borderBottom: '1px solid rgba(255,255,255,0.02)' }}>
                                    <td style={{ padding: '1rem', fontWeight: 'bold', color: 'var(--accent-glow)' }}>{att.ip}</td>
                                    <td style={{ padding: '1rem' }}>{att.country}</td>
                                    <td style={{ padding: '1rem' }}>{att.attempts}</td>
                                    <td style={{ padding: '1rem' }}>
                                        <span style={{ 
                                            padding: '2px 8px', 
                                            borderRadius: '4px', 
                                            background: att.risk === 'Critical' ? 'rgba(255,68,68,0.2)' : 'rgba(255,165,0,0.1)', 
                                            color: att.risk === 'Critical' ? 'var(--danger)' : 'var(--warning)',
                                            fontSize: '0.75rem',
                                            fontWeight: 'bold'
                                        }}>
                                            {att.risk}
                                        </span>
                                    </td>
                                    <td style={{ padding: '1rem', opacity: 0.6 }}>{att.lastSeen}</td>
                                </tr>
                            ))}
                        </tbody>
                    </table>
                </div>

                <div style={{ padding: '1.5rem', borderTop: '1px solid rgba(255,255,255,0.05)', display: 'flex', justifyContent: 'flex-end' }}>
                    <button className="glass-panel" style={{ display: 'flex', alignItems: 'center', gap: '8px', padding: '10px 20px', cursor: 'pointer' }}>
                        <Download size={18} /> Export Forensic Data
                    </button>
                </div>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>

    </motion.div>
  );
}

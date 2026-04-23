import React, { useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import { Loader2, Plus, Trash2, Server, Shield, Globe, HardDrive } from 'lucide-react';
import { apiFetch } from './api';

export default function PiholeTab({ token }) {
  const [internalTab, setInternalTab] = useState('STATS');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  // States for data
  const [stats, setStats] = useState(null);
  const [dnsRecords, setDnsRecords] = useState([]);
  const [dhcpLeases, setDhcpLeases] = useState([]);

  // Form states
  const [newDnsDomain, setNewDnsDomain] = useState('');
  const [newDnsIp, setNewDnsIp] = useState('');

  const fetchStats = async () => {
    setLoading(true); setError(null);
    try {
      const res = await apiFetch('/api/services/pihole/summary', { headers: { 'Authorization': `Bearer ${token}` }});
      if (!res.ok) throw new Error(await res.text());
      setStats(await res.json());
    } catch (e) { setError(e.message); }
    finally { setLoading(false); }
  };

  const fetchDns = async () => {
    setLoading(true); setError(null);
    try {
      const res = await apiFetch('/api/services/pihole/dns', { headers: { 'Authorization': `Bearer ${token}` }});
      if (!res.ok) throw new Error(await res.text());
      setDnsRecords(await res.json());
    } catch (e) { setError(e.message); }
    finally { setLoading(false); }
  };

  const fetchLeases = async () => {
    setLoading(true); setError(null);
    try {
      const res = await apiFetch('/api/services/pihole/network', { headers: { 'Authorization': `Bearer ${token}` }});
      if (!res.ok) throw new Error(await res.text());
      setDhcpLeases(await res.json());
    } catch (e) { setError(e.message); }
    finally { setLoading(false); }
  };

  const handleAddDns = async () => {
    try {
      const res = await apiFetch('/api/services/pihole/dns', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${token}` },
        body: JSON.stringify({ domain: newDnsDomain, ip: newDnsIp })
      });
      if (!res.ok) throw new Error(await res.text());
      setNewDnsDomain(''); setNewDnsIp('');
      fetchDns();
    } catch (e) { setError(e.message); }
  };

  const handleRemoveDns = async (domain) => {
    try {
      const res = await apiFetch(`/api/services/pihole/dns/${domain}`, {
        method: 'DELETE',
        headers: { 'Authorization': `Bearer ${token}` }
      });
      if (!res.ok) throw new Error(await res.text());
      fetchDns();
    } catch (e) { setError(e.message); }
  };

  useEffect(() => {
    if (internalTab === 'STATS') fetchStats();
    if (internalTab === 'DNS') fetchDns();
    if (internalTab === 'LEASES') fetchLeases();
  }, [internalTab]);

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
      
      {/* Internal Navigation */}
      <div style={{ display: 'flex', gap: '1rem', borderBottom: '1px solid var(--glass-border)', paddingBottom: '0.5rem' }}>
        <button onClick={() => setInternalTab('STATS')} style={{ background: 'none', border: 'none', color: internalTab === 'STATS' ? 'var(--accent-glow)' : 'var(--text-dim)', cursor: 'pointer', fontWeight: internalTab === 'STATS' ? 'bold' : 'normal' }}>Dashboard</button>
        <button onClick={() => setInternalTab('DNS')} style={{ background: 'none', border: 'none', color: internalTab === 'DNS' ? 'var(--accent-glow)' : 'var(--text-dim)', cursor: 'pointer', fontWeight: internalTab === 'DNS' ? 'bold' : 'normal' }}>Local DNS</button>
        <button onClick={() => setInternalTab('LEASES')} style={{ background: 'none', border: 'none', color: internalTab === 'LEASES' ? 'var(--accent-glow)' : 'var(--text-dim)', cursor: 'pointer', fontWeight: internalTab === 'LEASES' ? 'bold' : 'normal' }}>DHCP Leases</button>
      </div>

      {loading && <div style={{ display: 'flex', gap: '0.5rem', color: 'var(--accent-glow)' }}><Loader2 className="spin" size={20}/> Carregando API do Pi-hole...</div>}
      {error && <div style={{ color: 'var(--danger)', background: 'rgba(255,50,50,0.1)', padding: '1rem', borderRadius: '8px' }}>Erro ao conectar com Pi-hole: {error}</div>}

      {/* STATS VIEW */}
      {!loading && !error && internalTab === 'STATS' && stats && (
        <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: '1rem' }}>
          
          <div className="glass-panel" style={{ padding: '1.5rem', textAlign: 'center' }}>
            <Shield size={32} color="var(--accent-glow)" style={{ marginBottom: '1rem' }} />
            <h3 style={{ margin: 0, fontSize: '2rem', color: 'var(--text-main)' }}>{stats.ads_blocked_today.toLocaleString()}</h3>
            <span style={{ color: 'var(--text-dim)', fontSize: '0.85rem' }}>Bloqueados Hoje</span>
          </div>

          <div className="glass-panel" style={{ padding: '1.5rem', textAlign: 'center' }}>
            <Globe size={32} color="#3498db" style={{ marginBottom: '1rem' }} />
            <h3 style={{ margin: 0, fontSize: '2rem', color: 'var(--text-main)' }}>{stats.dns_queries_today.toLocaleString()}</h3>
            <span style={{ color: 'var(--text-dim)', fontSize: '0.85rem' }}>Consultas Processadas</span>
          </div>

          <div className="glass-panel" style={{ padding: '1.5rem', textAlign: 'center' }}>
            <Server size={32} color="var(--success)" style={{ marginBottom: '1rem' }} />
            <h3 style={{ margin: 0, fontSize: '2rem', color: 'var(--text-main)' }}>{stats.domains_being_blocked.toLocaleString()}</h3>
            <span style={{ color: 'var(--text-dim)', fontSize: '0.85rem' }}>Domínios na Blocklist</span>
          </div>
          
        </motion.div>
      )}

      {/* LOCAL DNS VIEW */}
      {!loading && !error && internalTab === 'DNS' && (
        <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
          <div className="glass-panel" style={{ padding: '1rem', display: 'flex', gap: '0.5rem', alignItems: 'center', flexWrap: 'wrap' }}>
            <input type="text" placeholder="Domínio (ex: server.lan)" value={newDnsDomain} onChange={(e)=>setNewDnsDomain(e.target.value)} style={{ flex: 1, padding: '0.6rem', borderRadius: '6px', background: 'rgba(0,0,0,0.3)', border: '1px solid var(--glass-border)', color: 'white' }} />
            <input type="text" placeholder="Endereço IP" value={newDnsIp} onChange={(e)=>setNewDnsIp(e.target.value)} style={{ flex: 1, padding: '0.6rem', borderRadius: '6px', background: 'rgba(0,0,0,0.3)', border: '1px solid var(--glass-border)', color: 'white' }} />
            <button onClick={handleAddDns} className="action-btn action-primary" style={{ padding: '0.6rem 1.2rem', whiteSpace: 'nowrap' }}><Plus size={16}/> Adicionar Host</button>
          </div>

          <div className="glass-panel" style={{ overflow: 'hidden' }}>
             <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left', color: 'var(--text-main)' }}>
               <thead>
                 <tr style={{ background: 'rgba(255,255,255,0.05)' }}>
                   <th style={{ padding: '1rem', borderBottom: '1px solid var(--glass-border)' }}>Domínio</th>
                   <th style={{ padding: '1rem', borderBottom: '1px solid var(--glass-border)' }}>Endereço IP</th>
                   <th style={{ padding: '1rem', borderBottom: '1px solid var(--glass-border)', textAlign: 'right' }}>Ação</th>
                 </tr>
               </thead>
               <tbody>
                 {dnsRecords.map((rec) => (
                   <tr key={rec.domain}>
                     <td style={{ padding: '1rem', borderBottom: '1px solid rgba(255,255,255,0.02)' }}>{rec.domain}</td>
                     <td style={{ padding: '1rem', borderBottom: '1px solid rgba(255,255,255,0.02)', fontFamily: 'monospace', color: 'var(--accent-glow)' }}>{rec.ip}</td>
                     <td style={{ padding: '1rem', borderBottom: '1px solid rgba(255,255,255,0.02)', textAlign: 'right' }}>
                       <button onClick={()=>handleRemoveDns(rec.domain)} style={{ background: 'none', border: 'none', color: 'var(--danger)', cursor: 'pointer' }}><Trash2 size={18}/></button>
                     </td>
                   </tr>
                 ))}
               </tbody>
             </table>
          </div>
        </motion.div>
      )}

      {/* LEASES VIEW */}
      {!loading && !error && internalTab === 'LEASES' && (
        <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }}>
          <div className="glass-panel" style={{ overflow: 'hidden' }}>
             <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left', color: 'var(--text-main)' }}>
               <thead>
                 <tr style={{ background: 'rgba(255,255,255,0.05)' }}>
                   <th style={{ padding: '1rem', borderBottom: '1px solid var(--glass-border)' }}>Hostname</th>
                   <th style={{ padding: '1rem', borderBottom: '1px solid var(--glass-border)' }}>MAC Address</th>
                   <th style={{ padding: '1rem', borderBottom: '1px solid var(--glass-border)' }}>Endereço IP</th>
                   <th style={{ padding: '1rem', borderBottom: '1px solid var(--glass-border)' }}>Status</th>
                 </tr>
               </thead>
               <tbody>
                 {dhcpLeases.map((rec) => (
                   <tr key={rec.mac}>
                     <td style={{ padding: '1rem', borderBottom: '1px solid rgba(255,255,255,0.02)' }}>{rec.name}</td>
                     <td style={{ padding: '1rem', borderBottom: '1px solid rgba(255,255,255,0.02)', fontFamily: 'monospace', color: 'var(--text-dim)' }}>{rec.mac}</td>
                     <td style={{ padding: '1rem', borderBottom: '1px solid rgba(255,255,255,0.02)', fontFamily: 'monospace', color: 'var(--accent-glow)' }}>{rec.ip}</td>
                     <td style={{ padding: '1rem', borderBottom: '1px solid rgba(255,255,255,0.02)' }}>
                        <span style={{ padding: '0.2rem 0.6rem', borderRadius: '12px', fontSize: '0.75rem', background: rec.status === 'active' ? 'rgba(10,191,159,0.2)' : 'rgba(255,255,255,0.1)', color: rec.status === 'active' ? 'var(--accent-glow)' : 'var(--text-dim)' }}>
                          {rec.status === 'active' ? 'Conectado' : 'Offline'}
                        </span>
                     </td>
                   </tr>
                 ))}
               </tbody>
             </table>
          </div>
        </motion.div>
      )}

    </div>
  );
}

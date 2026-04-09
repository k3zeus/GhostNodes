import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Network, Router, Box, Users, Share2, Terminal, PlayCircle, Loader2, CheckCircle, AlertCircle, Search, Eye, ShieldAlert, HelpCircle, UserPlus, Trash2, Key, UserCheck } from 'lucide-react';
import PiholeTab from './PiholeTab';

export default function ServicesTab({ token, role }) {
  const [activeSubTab, setActiveSubTab] = useState('ROUTING');
  const [showHelp, setShowHelp] = useState(false);
  const [logs, setLogs] = useState('');
  const [status, setStatus] = useState('idle'); 
  
  // States para Gestão de Usuários
  const [dashboardUsers, setDashboardUsers] = useState([]);
  const [loadingUsers, setLoadingUsers] = useState(false);
  
  // Dashboard User Form
  const [dashUsername, setDashUsername] = useState('');
  const [dashPassword, setDashPassword] = useState('');
  const [dashRole, setDashRole] = useState('viewer');
  
  // Linux User Form
  const [linuxUsername, setLinuxUsername] = useState('');
  const [linuxPassword, setLinuxPassword] = useState('');

  const isAdmin = role === 'admin';

  useEffect(() => {
    if (activeSubTab === 'USERS' && isAdmin) {
      fetchDashboardUsers();
    }
  }, [activeSubTab, isAdmin]);

  const fetchDashboardUsers = async () => {
    setLoadingUsers(true);
    try {
      const res = await fetch('http://localhost:8000/api/auth/users', {
        headers: { 'Authorization': `Bearer ${token}` }
      });
      if (res.ok) {
        setDashboardUsers(await res.json());
      }
    } catch (err) {
      console.error("Erro ao buscar usuários:", err);
    } finally {
      setLoadingUsers(false);
    }
  };

  const handleCreateDashUser = async (e) => {
    e.preventDefault();
    if (!dashUsername || !dashPassword) return;
    
    setStatus('loading');
    try {
      const res = await fetch('http://localhost:8000/api/auth/users', {
        method: 'POST',
        headers: { 
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}` 
        },
        body: JSON.stringify({ username: dashUsername, password: dashPassword, role: dashRole })
      });
      const data = await res.json();
      if (res.ok) {
        setLogs(prev => prev + `\n[SUCCESS] Dashboard user '${dashUsername}' created.\n`);
        setDashUsername(''); setDashPassword('');
        fetchDashboardUsers();
        setStatus('success');
      } else {
        setLogs(prev => prev + `\n[ERROR] ${data.detail}\n`);
        setStatus('error');
      }
    } catch (err) {
      setStatus('error');
    }
  };

  const handleDeleteDashUser = async (username) => {
    if (!window.confirm(`Confirma exclusão do usuário ${username}?`)) return;
    
    try {
      const res = await fetch(`http://localhost:8000/api/auth/users/${username}`, {
        method: 'DELETE',
        headers: { 'Authorization': `Bearer ${token}` }
      });
      if (res.ok) {
        setLogs(prev => prev + `\n[SUCCESS] Dashboard user '${username}' removed.\n`);
        fetchDashboardUsers();
      }
    } catch (err) {
      console.error("Erro ao deletar:", err);
    }
  };

  const handleCreateLinuxUser = async (e) => {
    e.preventDefault();
    if (!linuxUsername || !linuxPassword) return;
    
    setStatus('loading');
    try {
      const res = await fetch('http://localhost:8000/api/system/users/linux', {
        method: 'POST',
        headers: { 
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}` 
        },
        body: JSON.stringify({ username: linuxUsername, password: linuxPassword })
      });
      const data = await res.json();
      if (res.ok) {
        setLogs(prev => prev + `\n[SUCCESS] Linux system user '${linuxUsername}' created.\n`);
        setLinuxUsername(''); setLinuxPassword('');
        setStatus('success');
      } else {
        setLogs(prev => prev + `\n[ERROR] ${data.detail}\n`);
        setStatus('error');
      }
    } catch (err) {
      setStatus('error');
    }
  };

  const runScript = async (scriptPath, commandDisplayLabel) => {
    if (!isAdmin) {
      alert("Acesso negado: Apenas administradores podem executar scripts.");
      return;
    }
    setStatus('loading');
    setLogs(prev => prev + `\n---------------------------------------\n$ run => ${commandDisplayLabel}\n`);

    try {
      const response = await fetch('http://localhost:8000/api/actions/execute', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`
        },
        body: JSON.stringify({ script_path: scriptPath })
      });

      const data = await response.json();

      if (response.ok) {
        setStatus(data.status === 'success' ? 'success' : 'error');
        setLogs(prev => prev + `\n--- STDOUT ---\n${data.stdout || ''}\n--- STDERR ---\n${data.stderr || ''}\n`);
      } else {
        setStatus('error');
        setLogs(prev => prev + `\n[ERRO HTTP ${response.status}] ${data.detail}\n`);
      }
    } catch (err) {
      setStatus('error');
      setLogs(prev => prev + `\n[FALHA DE REDE] ${err.message}\n`);
    }
  };

  const tabs = [
    { id: 'ROUTING', label: 'Routing', icon: Router },
    { id: 'WIFI', label: 'Wi-Fi', icon: Network },
    { id: 'DOCKER', label: 'Docker', icon: Box },
    { id: 'DNS', label: 'DNS (Pi-Hole)', icon: Share2 },
    { id: 'VPN', label: 'VPN (Wireguard)', icon: ShieldAlert },
    { id: 'USERS', label: 'Users', icon: Users },
  ];

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>
      
      {/* Sub Menu Navbar */}
      <div style={{ display: 'flex', gap: '0.5rem', overflowX: 'auto', paddingBottom: '0.5rem', borderBottom: '1px solid rgba(255,255,255,0.05)' }}>
        {tabs.map((tab) => {
          const Icon = tab.icon;
          const isActive = activeSubTab === tab.id;
          return (
            <button
              key={tab.id}
              onClick={() => { setActiveSubTab(tab.id); setShowHelp(false); }}
              style={{
                display: 'flex',
                alignItems: 'center',
                gap: '0.6rem',
                padding: '0.6rem 1.2rem',
                borderRadius: '8px',
                border: 'none',
                background: isActive ? 'rgba(10, 191, 159, 0.15)' : 'transparent',
                color: isActive ? 'var(--accent-glow)' : 'var(--text-dim)',
                fontWeight: isActive ? 600 : 500,
                cursor: 'pointer',
                transition: 'all 0.2s',
                whiteSpace: 'nowrap'
              }}
            >
              <Icon size={16} />
              {tab.label}
            </button>
          );
        })}
      </div>

      {/* Dinâmico Content Area Panel */}
      <div style={{ display: 'flex', flexDirection: 'column' }}>
        <AnimatePresence mode="wait">
          
          <motion.div
            key={activeSubTab}
            initial={{ opacity: 0, scale: 0.98 }}
            animate={{ opacity: 1, scale: 1 }}
            exit={{ opacity: 0, scale: 1 }}
            transition={{ duration: 0.15 }}
            className="glass-panel"
            style={{ padding: '1.5rem', marginBottom: '0.5rem' }}
          >
            {/* ------------ VIEW: ROUTING ------------ */}
            {activeSubTab === 'ROUTING' && (
              <>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1.5rem' }}>
                  <h2 style={{ display: 'flex', alignItems: 'center', gap: '0.8rem', margin: 0, fontSize: '1.2rem', color: 'var(--text-main)' }}>
                    <Router size={22} color="var(--accent-glow)" /> Halfin Firewall & Routing
                  </h2>
                </div>
                
                <div style={{ display: 'flex', gap: '1rem', alignItems: 'center' }}>
                  <button onClick={() => runScript("halfin/routing.sh", "halfin/routing.sh")} disabled={status === 'loading' || !isAdmin} className="action-btn action-secondary">
                    {status === 'loading' ? <Loader2 size={18} className="spin" /> : <PlayCircle size={18} />}
                    {status === 'loading' ? 'Executando...' : 'Aplicar Regras GW de Rede'}
                  </button>
                </div>
              </>
            )}

            {/* ------------ VIEW: USERS (NOVO) ------------ */}
            {activeSubTab === 'USERS' && (
              <div style={{ display: 'flex', flexDirection: 'column', gap: '2rem' }}>
                {!isAdmin ? (
                  <div style={{ textAlign: 'center', padding: '2rem' }}>
                    <ShieldAlert size={48} color="var(--danger)" style={{ marginBottom: '1rem', opacity: 0.5 }} />
                    <h3 style={{ color: 'var(--text-main)' }}>Access Restrict</h3>
                    <p className="text-dim">You must be an administrator to manage users.</p>
                  </div>
                ) : (
                  <>
                    {/* Dashboard Users Section */}
                    <section>
                      <h3 style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', fontSize: '1.1rem', marginBottom: '1rem', color: 'var(--accent-glow)' }}>
                        <UserCheck size={20} /> Dashboard Users
                      </h3>
                      
                      <div style={{ display: 'grid', gridTemplateColumns: '1fr 350px', gap: '2rem' }}>
                        {/* Users List */}
                        <div className="glass-panel" style={{ padding: '0', overflow: 'hidden', border: '1px solid rgba(255,255,255,0.05)' }}>
                          <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left', fontSize: '0.9rem' }}>
                            <thead style={{ background: 'rgba(255,255,255,0.03)' }}>
                              <tr>
                                <th style={{ padding: '1rem' }}>Username</th>
                                <th style={{ padding: '1rem' }}>Role</th>
                                <th style={{ padding: '1rem', textAlign: 'right' }}>Action</th>
                              </tr>
                            </thead>
                            <tbody>
                              {dashboardUsers.map(u => (
                                <tr key={u.username} style={{ borderTop: '1px solid rgba(255,255,255,0.05)' }}>
                                  <td style={{ padding: '1rem' }}>{u.username}</td>
                                  <td style={{ padding: '1rem' }}>
                                    <span style={{ 
                                      padding: '2px 8px', borderRadius: '4px', fontSize: '0.75rem', fontWeight: 600,
                                      background: u.role === 'admin' ? 'rgba(10, 191, 159, 0.2)' : 'rgba(255,255,255,0.1)',
                                      color: u.role === 'admin' ? 'var(--accent-glow)' : 'var(--text-dim)'
                                    }}>
                                      {u.role.toUpperCase()}
                                    </span>
                                  </td>
                                  <td style={{ padding: '1rem', textAlign: 'right' }}>
                                    <button onClick={() => handleDeleteDashUser(u.username)} style={{ background: 'transparent', border: 'none', color: 'var(--danger)', cursor: 'pointer', padding: '4px' }}>
                                      <Trash2 size={16} />
                                    </button>
                                  </td>
                                </tr>
                              ))}
                            </tbody>
                          </table>
                        </div>

                        {/* Create Dash User Form */}
                        <form onSubmit={handleCreateDashUser} className="glass-panel" style={{ padding: '1.5rem', display: 'flex', flexDirection: 'column', gap: '1rem' }}>
                          <h4 style={{ margin: 0, fontSize: '0.9rem' }}>Add New Panel User</h4>
                          <input type="text" placeholder="Username" value={dashUsername} onChange={e => setDashUsername(e.target.value)} style={{ padding: '0.8rem', background: 'rgba(0,0,0,0.2)', border: '1px solid var(--glass-border)', color: 'white', borderRadius: '8px' }} />
                          <input type="password" placeholder="Password" value={dashPassword} onChange={e => setDashPassword(e.target.value)} style={{ padding: '0.8rem', background: 'rgba(0,0,0,0.2)', border: '1px solid var(--glass-border)', color: 'white', borderRadius: '8px' }} />
                          <select value={dashRole} onChange={e => setDashRole(e.target.value)} style={{ padding: '0.8rem', background: 'rgba(0,0,0,0.2)', border: '1px solid var(--glass-border)', color: 'white', borderRadius: '8px' }}>
                            <option value="viewer">Viewer (Read-only)</option>
                            <option value="admin">Administrator (Full Control)</option>
                          </select>
                          <button type="submit" disabled={status === 'loading'} className="action-btn action-secondary" style={{ width: '100%' }}>
                            <UserPlus size={18} /> Create Dashboard User
                          </button>
                        </form>
                      </div>
                    </section>

                    {/* Linux Users Section */}
                    <section style={{ borderTop: '1px solid rgba(255,255,255,0.1)', paddingTop: '2rem' }}>
                      <h3 style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', fontSize: '1.1rem', marginBottom: '1rem', color: 'var(--accent-base)' }}>
                        <Terminal size={20} /> Linux System Accounts
                      </h3>
                      <div style={{ display: 'grid', gridTemplateColumns: '1fr 350px', gap: '2rem' }}>
                        <div className="text-dim" style={{ fontSize: '0.9rem', lineHeight: 1.6 }}>
                          <p>Crie contas de sistema diretamente no nó. Esses usuários terão diretórios pessoais (`/home/user`) e acesso via SSH se o serviço estiver habilitado.</p>
                          <p style={{ marginTop: '0.5rem' }}><strong>Nota:</strong> Novos usuários de sistema no Linux são criados por padrão como membros do grupo básico, sem privilégios sudo.</p>
                        </div>
                        <form onSubmit={handleCreateLinuxUser} className="glass-panel" style={{ padding: '1.5rem', display: 'flex', flexDirection: 'column', gap: '1rem' }}>
                          <h4 style={{ margin: 0, fontSize: '0.9rem' }}>New Linux Account</h4>
                          <input type="text" placeholder="System Username" value={linuxUsername} onChange={e => setLinuxUsername(e.target.value)} style={{ padding: '0.8rem', background: 'rgba(0,0,0,0.2)', border: '1px solid var(--glass-border)', color: 'white', borderRadius: '8px' }} />
                          <input type="password" placeholder="System Password" value={linuxPassword} onChange={e => setLinuxPassword(e.target.value)} style={{ padding: '0.8rem', background: 'rgba(0,0,0,0.2)', border: '1px solid var(--glass-border)', color: 'white', borderRadius: '8px' }} />
                          <button type="submit" disabled={status === 'loading'} className="action-btn action-primary" style={{ width: '100%' }}>
                            <Key size={18} /> Provision Linux User
                          </button>
                        </form>
                      </div>
                    </section>
                  </>
                )}
              </div>
            )}

            {/* ------------ VIEW: DNS (PI-HOLE) ------------ */}
            {activeSubTab === 'DNS' && (
              <PiholeTab token={token} />
            )}

            {/* ------------ VIEW: PLACEHOLDERS ------------ */}
            {['WIFI', 'DOCKER', 'VPN'].includes(activeSubTab) && (
              <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', padding: '2rem', textAlign: 'center' }}>
                <Box size={32} color="var(--glass-border)" style={{ marginBottom: '1rem' }} />
                <h3 style={{ margin: '0 0 0.5rem 0', color: 'var(--text-main)', fontSize: '1.2rem' }}>Module Under Parametrization</h3>
                <p className="text-dim" style={{ maxWidth: '400px', lineHeight: 1.5, margin: 0 }}>
                  This module is transitioning to user-agnostic hardware support. Check back soon.
                </p>
              </div>
            )}
            
          </motion.div>
        </AnimatePresence>
      </div>

      {/* Global Terminal Console */}
      <div style={{
          background: '#0a0d11',
          border: '1px solid rgba(255,255,255,0.05)',
          borderRadius: '12px',
          padding: '1rem',
          minHeight: '220px',
          display: 'flex',
          flexDirection: 'column'
        }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1rem' }}>
            <h4 style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', color: 'var(--text-dim)', margin: 0, fontSize: '0.8rem', textTransform: 'uppercase' }}>
              <Terminal size={14}/> System Console
            </h4>
             <div style={{ display: 'flex', gap: '0.8rem', alignItems: 'center' }}>
               {status === 'loading' && <span style={{ color: 'var(--accent-glow)', fontSize: '0.8rem' }}><Loader2 size={12} className="spin"/> Busy</span>}
               <button onClick={() => {setLogs(''); setStatus('idle')}} style={{ background: 'transparent', border: '1px solid var(--glass-border)', color: 'var(--text-dim)', fontSize: '0.7rem', padding: '0.2rem 0.5rem', borderRadius: '4px', cursor: 'pointer' }}>Clear</button>
             </div>
          </div>
          
          <pre style={{
            margin: 0,
            whiteSpace: 'pre-wrap',
            color: '#1beaa2', 
            fontFamily: '"Fira Code", monospace',
            fontSize: '0.85rem',
            lineHeight: 1.6,
            overflowY: 'auto',
            flex: 1
          }}>
            {logs || '> Supervisor Standby...'}
          </pre>
      </div>
    </div>
  );
}

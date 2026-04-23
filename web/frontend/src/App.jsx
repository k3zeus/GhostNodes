import { useState, useEffect } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { Activity, Server, Database, HardDrive, Cpu, AlertCircle, LayoutDashboard, Shield, Settings, Wifi, Thermometer, MemoryStick, Moon, Sun, UserCircle, LogOut, Grid, Power, RotateCw } from 'lucide-react'
import LoginScreen from './LoginScreen'
import ServicesTab from './ServicesTab'
import GuardianTab from './GuardianTab'
import PiholeTab from './PiholeTab'
import ApplicationsTab from './ApplicationsTab'
import { apiFetch } from './api'

// Helper para decodificar JWT sem bibliotecas externas
const parseJwt = (token) => {
  try {
    return JSON.parse(atob(token.split('.')[1]));
  } catch (e) {
    return null;
  }
};

const NODE_INFO = {
  version: "v0.15",
  os: "Debian Bookworm",
  hardware: "Orangepi Zero 3"
}

function App() {
  const [hw, setHw] = useState(null)
  const [btc, setBtc] = useState(null)
  const [theme, setTheme] = useState('dark')
  const [activeTab, setActiveTab] = useState('dashboard')
  const [showPowerMenu, setShowPowerMenu] = useState(false)
  const [powerTarget, setPowerTarget] = useState(null) 
  
  const [token, setToken] = useState(() => localStorage.getItem('ghostnodes_jwt') || null)
  const [userData, setUserData] = useState(() => token ? parseJwt(token) : null)

  useEffect(() => {
    document.documentElement.setAttribute('data-theme', theme);
  }, [theme])

  useEffect(() => {
    if (!token) return;
    setUserData(parseJwt(token));

    const fetchHealth = async () => {
      const headers = { 'Authorization': `Bearer ${token}` }
      try {
        const res = await apiFetch('/api/system/hardware', { headers })
        if (res.ok) {
          setHw(await res.json())
        } else if (res.status === 401) {
           handleLogout()
        }
      } catch (err) { }
      
      try {
        const resBtc = await apiFetch('/api/bitcoin/status', { headers })
        if (resBtc.ok) {
          setBtc(await resBtc.json())
        } else if (resBtc.status === 401) {
           handleLogout()
        }
      } catch (err) { }
    }

    fetchHealth()
    const intv = setInterval(fetchHealth, 3000)
    return () => clearInterval(intv)
  }, [token])

  const toggleTheme = () => {
    setTheme(prev => prev === 'dark' ? 'light' : 'dark')
  }

  const handleLoginSuccess = (jwtToken) => {
    localStorage.setItem('ghostnodes_jwt', jwtToken)
    setToken(jwtToken)
    setUserData(parseJwt(jwtToken))
  }

  const handleLogout = () => {
    localStorage.removeItem('ghostnodes_jwt')
    setToken(null)
    setUserData(null)
    setHw(null)
    setBtc(null)
  }

  const handlePowerCommand = async (action) => {
    if (userData?.role !== 'admin') {
      alert('Acesso negado: Apenas administradores podem controlar a energia.');
      return;
    }

    try {
      const res = await apiFetch(`/api/system/power?action=${action}`, {
        method: 'POST',
        headers: { 'Authorization': `Bearer ${token}` }
      })
      if (res.ok) {
        alert(`Comando ${action} enviado com sucesso!`)
        setPowerTarget(null)
      } else {
        const data = await res.json()
        alert(`Erro: ${data.detail || 'Falha ao executar comando'}`)
      }
    } catch (err) {
      alert('Erro ao enviar comando de energia.')
    }
  }

  if (!token) {
    return <LoginScreen onLoginSuccess={handleLoginSuccess} />
  }

  const getNetworkIcon = (type, status) => {
    if (type === 'wired') return <Server size={24} color={status === 'online' ? 'var(--success)' : 'var(--text-dim)'} />;
    return <Wifi size={24} color={status === 'online' ? 'var(--success)' : 'var(--text-dim)'} />;
  }

  const isAdmin = userData?.role === 'admin';

  return (
    <div className="app-layout">
      <aside className="sidebar">
        <div className="sidebar-header">
          <img src="/logo.jpg" alt="GhostNodes Logo" style={{ width: 44, borderRadius: 8 }} />
          <h1 className="sidebar-title">Ghost Nodes</h1>
        </div>

        <nav className="nav-menu" style={{ display: 'flex', flexDirection: 'column', gap: '0.4rem' }}>
          <a href="#" className={`nav-item ${activeTab === 'dashboard' ? 'active' : ''}`} onClick={(e) => { e.preventDefault(); setActiveTab('dashboard'); }}>
            <LayoutDashboard size={18} /> Dashboard
          </a>
          <a href="#" className={`nav-item ${activeTab === 'guardian' ? 'active' : ''}`} onClick={(e) => { e.preventDefault(); setActiveTab('guardian'); }}>
            <Shield size={18} /> Guardian
          </a>
          <a href="#" className={`nav-item ${activeTab === 'services' ? 'active' : ''}`} onClick={(e) => { e.preventDefault(); setActiveTab('services'); }}>
            <Activity size={18} /> Services
          </a>
          <a href="#" className={`nav-item ${activeTab === 'pihole' ? 'active' : ''}`} onClick={(e) => { e.preventDefault(); setActiveTab('pihole'); }}>
            <Shield size={18} color="var(--accent-glow)" /> Pi-hole DNS
          </a>
          <a href="#" className={`nav-item ${activeTab === 'apps' ? 'active' : ''}`} onClick={(e) => { e.preventDefault(); setActiveTab('apps'); }}>
            <Grid size={18} /> Applications
          </a>
          {isAdmin && (
            <a href="#" className={`nav-item ${activeTab === 'settings' ? 'active' : ''}`} onClick={(e) => { e.preventDefault(); setActiveTab('settings'); }}>
              <Settings size={18} /> Settings
            </a>
          )}
        </nav>

        <div className="node-footer desktop-only-footer">
          <strong>HALFIN NODE {NODE_INFO.version}</strong><br/>
          User: {userData?.sub || '---'}<br/>
          Role: <span style={{ color: isAdmin ? 'var(--accent-glow)' : 'var(--text-dim)' }}>{userData?.role || '---'}</span><br/>
          {NODE_INFO.os}<br/>
          {NODE_INFO.hardware}
        </div>
      </aside>

      <main className="content-area">
        <header style={{ marginBottom: '2rem', display: 'flex', flexWrap: 'wrap', gap: '1.5rem', justifyContent: 'space-between', alignItems: 'center' }}>
           <div style={{ flex: '1 1 300px' }}>
             <h2 className="gradient-text" style={{ fontSize: '2.4rem', fontWeight: 800, letterSpacing: '1px', margin: 0, whiteSpace: 'nowrap' }}>SOVEREIGNTY</h2>
             <p className="text-dim" style={{ marginTop: '0.5rem', fontSize: '0.9rem', lineHeight: 1.4 }}>Security, privacy and freedom. Your gate to the hyperbitcoinized future.</p>
           </div>
           
            <div style={{ display: 'flex', alignItems: 'center', gap: '1rem', position: 'relative' }}>
               <button onClick={toggleTheme} className="glass-panel" style={{ background: 'transparent', padding: '0.6rem', border: '1px solid var(--glass-border)', borderRadius: '50%', color: 'var(--text-main)' }}>
                 {theme === 'dark' ? <Sun size={20} /> : <Moon size={20} />}
               </button>

               {isAdmin && (
                 <div style={{ position: 'relative' }}>
                   <button onClick={() => setShowPowerMenu(!showPowerMenu)} className="glass-panel" style={{ background: 'transparent', padding: '0.6rem', border: '1px solid var(--glass-border)', borderRadius: '50%', color: 'var(--danger)' }}>
                     <Power size={20} />
                   </button>

                   {showPowerMenu && (
                     <motion.div 
                       initial={{ opacity: 0, y: 10 }} 
                       animate={{ opacity: 1, y: 0 }}
                       className="glass-panel" 
                       style={{ position: 'absolute', top: '120%', right: 0, width: '180px', padding: '0.5rem', zIndex: 100, border: '1px solid var(--danger)' }}
                     >
                       <button 
                         onClick={() => { setPowerTarget('reboot'); setShowPowerMenu(false); }}
                         style={{ width: '100%', padding: '0.8rem', background: 'transparent', border: 'none', color: 'var(--text-main)', display: 'flex', alignItems: 'center', gap: '8px', cursor: 'pointer', borderRadius: '6px' }}
                         className="nav-item"
                       >
                         <RotateCw size={16} /> Reboot Node
                       </button>
                       <button 
                         onClick={() => { setPowerTarget('shutdown'); setShowPowerMenu(false); }}
                         style={{ width: '100%', padding: '0.8rem', background: 'transparent', border: 'none', color: 'var(--danger)', display: 'flex', alignItems: 'center', gap: '8px', cursor: 'pointer', borderRadius: '6px' }}
                         className="nav-item"
                       >
                         <Power size={16} /> Halt System
                       </button>
                     </motion.div>
                   )}
                 </div>
               )}
               
               <button onClick={handleLogout} style={{ background: 'transparent', border: 'none', cursor: 'pointer' }}>
                 <div style={{ width: 44, height: 44, borderRadius: '50%', background: 'linear-gradient(135deg, var(--accent-glow) 0%, var(--accent-base) 100%)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#1f2937' }}>
                   <LogOut size={22} />
                 </div>
               </button>
            </div>
         </header>

         {/* Power Confirmation Modal */}
         <AnimatePresence>
           {powerTarget && (
             <motion.div 
               initial={{ opacity: 0 }} 
               animate={{ opacity: 1 }} 
               exit={{ opacity: 0 }}
               style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.8)', zIndex: 1000, display: 'flex', alignItems: 'center', justifyContent: 'center', padding: '1rem' }}
             >
               <motion.div 
                 initial={{ scale: 0.9 }} 
                 animate={{ scale: 1 }} 
                 className="glass-panel" 
                 style={{ width: '100%', maxWidth: '400px', padding: '2rem', textAlign: 'center', border: '1px solid var(--danger)' }}
               >
                 <AlertCircle size={48} color="var(--danger)" style={{ marginBottom: '1rem' }} />
                 <h2 style={{ marginBottom: '1rem' }}>Confirm {powerTarget === 'reboot' ? 'Reboot' : 'Shutdown'}?</h2>
                 <p className="text-dim" style={{ marginBottom: '2rem' }}>
                    This action will disconnect you from the node. Are you sure you want to proceed?
                 </p>
                 <div style={{ display: 'flex', gap: '1rem' }}>
                   <button onClick={() => setPowerTarget(null)} className="glass-panel" style={{ flex: 1, padding: '0.8rem', cursor: 'pointer' }}>Cancel</button>
                   <button 
                     onClick={() => handlePowerCommand(powerTarget)} 
                     style={{ flex: 1, padding: '0.8rem', background: 'var(--danger)', color: 'white', border: 'none', borderRadius: '8px', fontWeight: 'bold', cursor: 'pointer' }}
                   >
                     Confirm
                   </button>
                 </div>
               </motion.div>
             </motion.div>
           )}
         </AnimatePresence>

        {activeTab === 'dashboard' && (
          <>
            <section style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))', gap: '1rem', marginBottom: '2.5rem' }}>
              <motion.div className="glass-panel" style={{ padding: '1.2rem', display: 'flex', alignItems: 'center', gap: '1rem' }} initial={{ opacity: 0 }} animate={{ opacity: 1 }}>
                <div style={{ background: 'rgba(128,128,128,0.1)', padding: '0.6rem', borderRadius: '10px' }}>
                  <Thermometer size={24} color="var(--accent-base)" />
                </div>
                <div>
                  <p className="text-dim" style={{ fontSize: '0.7rem', textTransform: 'uppercase' }}>CPU TEMP</p>
                  <h3 style={{ fontSize: '1.2rem', margin: 0 }}>{hw?.temperature_c > 0 ? `${hw.temperature_c.toFixed(1)}°C` : 'N/A'}</h3>
                </div>
              </motion.div>

              <motion.div className="glass-panel" style={{ padding: '1.2rem', display: 'flex', alignItems: 'center', gap: '1rem' }} initial={{ opacity: 0 }} animate={{ opacity: 1 }}>
                <div style={{ background: 'rgba(128,128,128,0.1)', padding: '0.6rem', borderRadius: '10px' }}>
                  <MemoryStick size={24} color="var(--accent-glow)" />
                </div>
                <div style={{ flex: 1 }}>
                  <p className="text-dim" style={{ fontSize: '0.7rem', textTransform: 'uppercase' }}>Memory</p>
                  <h3 style={{ fontSize: '1.2rem', margin: 0 }}>{hw ? `${hw.memory_percent}%` : '--'}</h3>
                  <div style={{ height: '5px', background: 'rgba(0,0,0,0.2)', borderRadius: '3px', marginTop: '0.5rem', overflow: 'hidden' }}>
                    <div style={{ height: '100%', width: `${hw ? hw.memory_percent : 0}%`, background: 'linear-gradient(90deg, #10b981 0%, #34d399 100%)', borderRadius: '3px', transition: 'width 0.5s ease-out' }} />
                  </div>
                </div>
              </motion.div>

              {hw?.network && Object.entries(hw.network).map(([key, data]) => {
                if (data.status === 'offline') return null; 
                return (
                  <motion.div key={key} className="glass-panel" style={{ padding: '1.2rem', display: 'flex', alignItems: 'center', gap: '1.2rem' }} initial={{ opacity: 0 }} animate={{ opacity: 1 }}>
                    <div style={{ background: 'rgba(128,128,128,0.1)', padding: '0.6rem', borderRadius: '10px' }}>
                      {getNetworkIcon(key, data.status)}
                    </div>
                    <div style={{ overflow: 'hidden' }}>
                      <p className="text-dim" style={{ fontSize: '0.7rem', textTransform: 'uppercase' }}>{key === 'wlan0' ? 'ACCESS POINT' : key === 'wlan1' ? 'WAN CLIENT' : 'ETHERNET'}</p>
                      <h3 style={{ fontSize: '1rem', margin: 0, textOverflow: 'ellipsis', overflow: 'hidden' }}>{data.ip}</h3>
                    </div>
                  </motion.div>
                );
              })}
            </section>

            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(300px, 1fr))', gap: '2rem' }}>
              <motion.div className="glass-panel" initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1 }} style={{ padding: '1.5rem' }}>
                <h2 style={{ display: 'flex', alignItems: 'center', gap: '0.8rem', fontSize: '1.1rem', marginBottom: '1.5rem' }}>
                  <Database size={20} color="var(--accent-glow)"/> Bitcoin Node Status
                </h2>
                {!btc ? (
                  <p className="text-dim">RPC Standby...</p>
                ) : btc.status === 'online' ? (
                  <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
                    <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                      <span className="text-dim">Height</span>
                      <span style={{ color: 'var(--success)', fontWeight: 'bold' }}>#{btc.blocks}</span>
                    </div>
                    <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                      <span className="text-dim">Sync</span>
                      <span>{(btc.verificationprogress * 100).toFixed(2)}%</span>
                    </div>
                  </div>
                ) : (
                  <p className="text-warning">{btc.message || 'Status indetectado'}</p>
                )}
              </motion.div>
              
              <motion.div className="glass-panel" initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1 }} style={{ padding: '1.5rem', display: 'flex', flexDirection: 'column', justifyContent: 'center', alignItems: 'center' }}>
                 <Cpu size={32} color="var(--accent-base)" style={{ marginBottom: '1rem', opacity: 0.7 }} />
                 <p className="text-dim">Node Performance Optimal</p>
              </motion.div>
            </div>
          </>
        )}

        {activeTab === 'guardian' && <GuardianTab />}
        {activeTab === 'services' && <ServicesTab token={token} role={userData?.role} />}
        {activeTab === 'pihole' && <PiholeTab token={token} />}
        {activeTab === 'apps' && <ApplicationsTab token={token} />}
        {activeTab === 'settings' && (
          <div className="glass-panel" style={{ padding: '2rem', textAlign: 'center' }}>
            <Settings size={48} className="text-dim" style={{ marginBottom: '1rem' }} />
            <h2>System Settings</h2>
            <p className="text-dim">Módulo em desenvolvimento</p>
          </div>
        )}

        <div className="node-footer mobile-only-footer">
          <strong>HALFIN NODE {NODE_INFO.version}</strong> | {userData?.sub}
        </div>
      </main>
    </div>
  )
}

export default App

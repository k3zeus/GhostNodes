import { useState, useEffect } from 'react'
import { motion } from 'framer-motion'
import { Activity, Server, Database, HardDrive, Cpu, AlertCircle, LayoutDashboard, Shield, Settings, Wifi, Thermometer, MemoryStick, Moon, Sun, UserCircle, LogOut } from 'lucide-react'
import LoginScreen from './LoginScreen'
import ServicesTab from './ServicesTab'

// Informações simuladas da sessão/node para o Layout
const NODE_INFO = {
  version: "v0.1",
  user: "PLEB",
  os: "Debian Bookworm",
  hardware: "Orangepi Zero 3"
}

function App() {
  const [hw, setHw] = useState(null)
  const [btc, setBtc] = useState(null)
  const [theme, setTheme] = useState('dark')
  const [activeTab, setActiveTab] = useState('dashboard')
  
  // Controle de estado JWT
  const [token, setToken] = useState(() => localStorage.getItem('ghostnodes_jwt') || null)

  useEffect(() => {
    document.documentElement.setAttribute('data-theme', theme);
  }, [theme])

  useEffect(() => {
    if (!token) return;

    const fetchHealth = async () => {
      const headers = { 'Authorization': `Bearer ${token}` }
      try {
        const res = await fetch('http://localhost:8000/api/system/hardware', { headers })
        if (res.ok) {
          setHw(await res.json())
        } else if (res.status === 401) {
           handleLogout()
        }
      } catch (err) { }
      
      try {
        const resBtc = await fetch('http://localhost:8000/api/bitcoin/status', { headers })
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
  }

  const handleLogout = () => {
    localStorage.removeItem('ghostnodes_jwt')
    setToken(null)
    setHw(null)
    setBtc(null)
  }

  if (!token) {
    return <LoginScreen onLoginSuccess={handleLoginSuccess} />
  }

  return (
    <div className="app-layout">
      {/* Sidebar Responsive */}
      <aside className="sidebar">
        <div className="sidebar-header">
          <img src="/logo.jpg" alt="GhostNodes Logo" style={{ width: 44, borderRadius: 8 }} />
          <h1 className="sidebar-title">
            Ghost Nodes
          </h1>
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
          <a href="#" className={`nav-item ${activeTab === 'settings' ? 'active' : ''}`} onClick={(e) => { e.preventDefault(); setActiveTab('settings'); }}>
            <Settings size={18} /> Settings
          </a>
        </nav>

        {/* Footer do Menu Desktop */}
        <div className="node-footer desktop-only-footer">
          <strong>HALFIN NODE {NODE_INFO.version}</strong><br/>
          User: {NODE_INFO.user}<br/>
          {NODE_INFO.os}<br/>
          {NODE_INFO.hardware}
        </div>
      </aside>

      {/* Main Content */}
      <main className="content-area">
        <header style={{ marginBottom: '2rem', display: 'flex', flexWrap: 'wrap', gap: '1.5rem', justifyContent: 'space-between', alignItems: 'center' }}>
           <div style={{ flex: '1 1 300px' }}>
             <h2 className="gradient-text" style={{ fontSize: '2.2rem', fontWeight: 800, letterSpacing: '2px', margin: 0, whiteSpace: 'nowrap' }}>SOVEREIGN</h2>
             <p className="text-dim" style={{ marginTop: '0.5rem', fontSize: '0.85rem', lineHeight: 1.4 }}>Keep your data and identity with you. Keep your real money in your pocket.</p>
           </div>
           
           {/* Top Right Controls: Theme Toggle & User Auth */}
           <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
              <button 
                onClick={toggleTheme} 
                style={{ background: 'transparent', border: '1px solid var(--glass-border)', borderRadius: '50%', padding: '0.6rem', cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'var(--text-main)', transition: 'background 0.2s' }}
                onMouseOver={e=>e.currentTarget.style.background='var(--primary-hover-bg)'} 
                onMouseOut={e=>e.currentTarget.style.background='transparent'}
                title="Toggle Theme"
              >
                {theme === 'dark' ? <Sun size={20} /> : <Moon size={20} />}
              </button>
              
              <button 
                onClick={handleLogout}
                style={{ background: 'transparent', border: 'none', cursor: 'pointer', padding: 0 }}
                title="Logout"
              >
                <div style={{ width: 44, height: 44, borderRadius: '50%', background: 'linear-gradient(135deg, var(--accent-glow) 0%, var(--accent-base) 100%)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#1f2937', boxShadow: '0 4px 15px rgba(0,0,0,0.2)' }}>
                  <LogOut size={22} />
                </div>
              </button>
           </div>
        </header>

        {/* Tab Routing */}
        {activeTab === 'dashboard' && (
          <>
            <section style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(230px, 1fr))', gap: '1rem', marginBottom: '2.5rem' }}>
              
              <motion.div className="glass-panel" style={{ padding: '1rem', display: 'flex', alignItems: 'center', gap: '1rem' }} initial={{ opacity: 0, y: -10 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.1 }}>
                <div style={{ background: 'rgba(128,128,128,0.1)', padding: '0.8rem', borderRadius: '12px' }}>
                  <Thermometer size={24} color="var(--accent-base)" />
                </div>
                <div>
                  <p className="text-dim" style={{ fontSize: '0.8rem', textTransform: 'uppercase', letterSpacing: '1px' }}>Temperature</p>
                  <h3 style={{ fontSize: '1.4rem', fontWeight: 700, margin: '2px 0 0 0', color: 'var(--text-main)' }}>
                    {hw ? (hw.temperature_c > 0 ? `${hw.temperature_c} °C` : 'N/A') : '--'}
                  </h3>
                </div>
              </motion.div>

              <motion.div className="glass-panel" style={{ padding: '1rem', display: 'flex', alignItems: 'center', gap: '1rem' }} initial={{ opacity: 0, y: -10 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.2 }}>
                 <div style={{ background: 'rgba(128,128,128,0.1)', padding: '0.8rem', borderRadius: '12px' }}>
                  <MemoryStick size={24} color="var(--accent-glow)" />
                </div>
                <div style={{ flex: 1 }}>
                  <p className="text-dim" style={{ fontSize: '0.8rem', textTransform: 'uppercase', letterSpacing: '1px' }}>Memory</p>
                  
                  {hw && hw.memory_total_mb ? (
                    <div style={{ display: 'flex', flexDirection: 'column', gap: '0.4rem', marginTop: '0.3rem' }}>
                      <div style={{ display: 'flex', flexWrap: 'wrap', justifyContent: 'space-between', alignItems: 'baseline', gap: '0.5rem' }}>
                        <span style={{ fontSize: '1.2rem', fontWeight: 700, color: 'var(--text-main)' }}>{hw.memory_percent}%</span>
                        <span style={{ fontSize: '0.75rem', color: 'var(--text-dim)', whiteSpace: 'nowrap' }}>
                          {(hw.memory_used_mb / 1024).toFixed(1)}GB / {(hw.memory_total_mb / 1024).toFixed(1)}GB
                        </span>
                      </div>
                      <div style={{ width: '100%', height: '6px', background: 'rgba(0,0,0,0.2)', borderRadius: '4px', overflow: 'hidden' }}>
                         <div style={{ height: '100%', width: `${hw.memory_percent}%`, background: 'var(--accent-glow)', borderRadius: '4px', transition: 'width 0.4s ease' }} />
                      </div>
                    </div>
                  ) : (
                     <h3 style={{ fontSize: '1.4rem', fontWeight: 700, margin: '2px 0 0 0', color: 'var(--text-main)' }}>--</h3>
                  )}
                </div>
              </motion.div>

              <motion.div className="glass-panel" style={{ padding: '1rem', display: 'flex', alignItems: 'center', gap: '1rem' }} initial={{ opacity: 0, y: -10 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.3 }}>
                 <div style={{ background: 'rgba(128,128,128,0.1)', padding: '0.8rem', borderRadius: '12px' }}>
                  <Wifi size={24} color={hw?.network?.wlan0?.status === 'online' ? 'var(--success)' : 'var(--text-dim)'} />
                </div>
                <div>
                  <p className="text-dim" style={{ fontSize: '0.8rem', textTransform: 'uppercase', letterSpacing: '1px' }}>WLAN0 (Private)</p>
                  <div style={{ margin: '2px 0 0 0', display: 'flex', flexDirection: 'column' }}>
                    <span style={{ fontSize: '1rem', fontWeight: 700, color: 'var(--text-main)' }}>{hw ? hw.network?.wlan0?.ip : '--'}</span>
                    <span style={{ fontSize: '0.75rem', color: 'var(--accent-base)'}}>{hw ? `${hw.network?.wlan0?.connected_hosts} devices` : ''}</span>
                  </div>
                </div>
              </motion.div>

              <motion.div className="glass-panel" style={{ padding: '1rem', display: 'flex', alignItems: 'center', gap: '1rem' }} initial={{ opacity: 0, y: -10 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.4 }}>
                 <div style={{ background: 'rgba(128,128,128,0.1)', padding: '0.8rem', borderRadius: '12px' }}>
                  <Wifi size={24} color={hw?.network?.wlan1?.status === 'online' ? 'var(--success)' : 'var(--text-dim)'} />
                </div>
                <div>
                  <p className="text-dim" style={{ fontSize: '0.8rem', textTransform: 'uppercase', letterSpacing: '1px' }}>WLAN1 (Public)</p>
                  <div style={{ margin: '2px 0 0 0', display: 'flex', flexDirection: 'column' }}>
                    <span style={{ fontSize: '1rem', fontWeight: 700, color: 'var(--text-main)' }}>{hw ? hw.network?.wlan1?.ip : '--'}</span>
                    <span style={{ fontSize: '0.75rem', color: 'var(--accent-base)'}}>{hw ? `${hw.network?.wlan1?.connected_hosts} hosts` : ''}</span>
                  </div>
                </div>
              </motion.div>

            </section>

            {/* Dashboard Details Grid */}
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(280px, 1fr))', gap: '2rem' }}>
              
              <motion.div className="glass-panel" initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.5 }}>
                <h2 style={{ display: 'flex', alignItems: 'center', gap: '0.8rem', marginBottom: '1.5rem', fontSize: '1.1rem', color: 'var(--text-main)' }}>
                  <Database size={20} color="var(--accent-glow)"/> Bitcoin Node Core
                </h2>
                
                {!btc ? (
                  <p className="text-dim" style={{ display: 'flex', gap: '0.5rem', alignItems: 'center'}}>
                    <AlertCircle size={16}/> Sincronizando RPC...
                  </p>
                ) : btc.status === 'error' || btc.status === 'offline' ? (
                   <p className="text-danger" style={{ display: 'flex', gap: '0.5rem', alignItems: 'center'}}>
                    Offline: Blockchain unreachable
                  </p>
                ) : (
                  <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', paddingBottom: '0.5rem', borderBottom: '1px solid var(--glass-border)'}}>
                      <span className="text-dim">Block Height</span>
                      <span style={{ fontWeight: 600, fontSize: '1.1rem', color: 'var(--success)' }}>#{btc.blocks}</span>
                    </div>
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', paddingBottom: '0.5rem', borderBottom: '1px solid var(--glass-border)'}}>
                      <span className="text-dim">Verification Progress</span>
                      <span style={{ fontWeight: 600, fontSize: '1.1rem', color: 'var(--text-main)' }}>{(btc.verificationprogress * 100).toFixed(2)}%</span>
                    </div>
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center'}}>
                      <span className="text-dim">Active Connections</span>
                      <span style={{ fontWeight: 600, fontSize: '1.1rem', color: 'var(--text-main)' }}>{btc.connections} Peers</span>
                    </div>
                  </div>
                )}
              </motion.div>

            </div>
          </>
        )}

        {/* Módulo de Serviços (Halfin) */}
        {activeTab === 'services' && (
          <ServicesTab token={token} />
        )}

        {/* Mobile-only Footer */}
        <div className="node-footer mobile-only-footer">
          <strong>HALFIN NODE {NODE_INFO.version}</strong> | User: {NODE_INFO.user}<br/>
          {NODE_INFO.os} | {NODE_INFO.hardware}
        </div>

      </main>
    </div>
  )
}

export default App

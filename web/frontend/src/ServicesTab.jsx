import React, { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Network, Router, Box, Users, Share2, Terminal, PlayCircle, Loader2, CheckCircle, AlertCircle, Search, Eye, ShieldAlert, HelpCircle } from 'lucide-react';
import PiholeTab from './PiholeTab';

export default function ServicesTab({ token }) {
  const [activeSubTab, setActiveSubTab] = useState('ROUTING');
  const [showHelp, setShowHelp] = useState(false);
  const [logs, setLogs] = useState('');
  const [status, setStatus] = useState('idle'); // idle, loading, success, error

  const runScript = async (scriptPath, commandDisplayLabel) => {
    setStatus('loading');
    setLogs(prev => prev + `\n---------------------------------------\n$ run => ${commandDisplayLabel}\n[Aguardando processamento e resposta Backend...]\n`);

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
        setLogs(prev => prev + `\n--- STDOUT ---\n${data.stdout || ''}\n--- STDERR ---\n${data.stderr || ''}\n[Exit Code: ${data.exit_code}]\n`);
      } else {
        setStatus('error');
        setLogs(prev => prev + `\n[ERRO HTTP ${response.status}] ${data.detail || 'Desconhecido'}\n`);
      }
    } catch (err) {
      setStatus('error');
      setLogs(prev => prev + `\n[FALHA DE REDE] ${err.message}\nVerifique se o Backend FastAPI está rodando.\n`);
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
                  <button onClick={() => setShowHelp(!showHelp)} style={{ background: 'transparent', border: 'none', color: 'var(--text-dim)', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: '0.4rem', fontSize: '0.8rem' }}>
                    <HelpCircle size={16} /> {showHelp ? 'Ocultar Ajuda' : 'Ajuda'}
                  </button>
                </div>
                
                {showHelp && (
                  <motion.div initial={{ opacity: 0, height: 0 }} animate={{ opacity: 1, height: 'auto' }} style={{ background: 'rgba(255,255,255,0.03)', padding: '1rem', borderRadius: '8px', marginBottom: '1.5rem', border: '1px solid var(--glass-border)' }}>
                    <p className="text-dim" style={{ fontSize: '0.85rem', margin: 0, lineHeight: 1.5 }}>
                      Executa a carga das regras iptables e ip_forwarding via nat, garantindo que portas ethernet compartilhem a Bridge wlan1 (Internet Pública) para a wlan0 (LAN Privada isolada).
                    </p>
                  </motion.div>
                )}
                
                <div style={{ display: 'flex', gap: '1rem', alignItems: 'center' }}>
                  <button onClick={() => runScript("halfin/routing.sh", "halfin/routing.sh")} disabled={status === 'loading'} className="action-btn action-secondary">
                    {status === 'loading' ? <Loader2 size={18} className="spin" /> : <PlayCircle size={18} />}
                    {status === 'loading' ? 'Executando...' : 'Aplicar Regras GW de Rede'}
                  </button>
                </div>
              </>
            )}

            {/* ------------ VIEW: WIFI ------------ */}
            {activeSubTab === 'WIFI' && (
              <>
                 <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1.5rem' }}>
                  <h2 style={{ display: 'flex', alignItems: 'center', gap: '0.8rem', margin: 0, fontSize: '1.2rem', color: 'var(--text-main)' }}>
                    <Network size={22} color="var(--accent-glow)" /> Ferramentas Wireless
                  </h2>
                  <button onClick={() => setShowHelp(!showHelp)} style={{ background: 'transparent', border: 'none', color: 'var(--text-dim)', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: '0.4rem', fontSize: '0.8rem' }}>
                    <HelpCircle size={16} /> {showHelp ? 'Ocultar Ajuda' : 'Ajuda'}
                  </button>
                </div>

                {showHelp && (
                  <motion.div initial={{ opacity: 0, height: 0 }} animate={{ opacity: 1, height: 'auto' }} style={{ background: 'rgba(255,255,255,0.03)', padding: '1rem', borderRadius: '8px', marginBottom: '1.5rem', border: '1px solid var(--glass-border)' }}>
                    <p className="text-dim" style={{ fontSize: '0.85rem', margin: 0, lineHeight: 1.5 }}>
                       Inspeção e conexão de interfaces Wi-fi do Hardware. Identifique SSIDs ou force um escaneamento em tempo real do ambiente de rede ao redor do Nó.
                    </p>
                  </motion.div>
                )}
                
                <div style={{ display: 'flex', gap: '1rem', flexWrap: 'wrap' }}>
                  <button onClick={() => runScript("halfin/tools/wifi_show.sh", "wifi_show.sh")} disabled={status === 'loading'} className="action-btn action-secondary">
                    {status === 'loading' ? <Loader2 size={18} className="spin" /> : <Eye size={18} />}
                    Mostrar Wi-Fi Atual
                  </button>

                  <button onClick={() => runScript("halfin/tools/wifi_scan.sh", "wifi_scan.sh")} disabled={status === 'loading'} className="action-btn action-secondary">
                    {status === 'loading' ? <Loader2 size={18} className="spin" /> : <Search size={18} />}
                    Scanear Redes Proximas
                  </button>
                </div>
              </>
            )}

            {/* ------------ VIEW: DNS (PI-HOLE) ------------ */}
            {activeSubTab === 'DNS' && (
              <>
                 <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1.5rem' }}>
                  <h2 style={{ display: 'flex', alignItems: 'center', gap: '0.8rem', margin: 0, fontSize: '1.2rem', color: 'var(--text-main)' }}>
                    <Share2 size={22} color="var(--accent-glow)" /> Pi-hole v6 Console
                  </h2>
                </div>
                <PiholeTab token={token} />
              </>
            )}

            {/* ------------ VIEW: PLACEHOLDERS ------------ */}
            {['DOCKER', 'USERS', 'VPN'].includes(activeSubTab) && (
              <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', padding: '1rem', textAlign: 'center' }}>
                <Box size={32} color="var(--glass-border)" style={{ marginBottom: '1rem' }} />
                <h3 style={{ margin: '0 0 0.5rem 0', color: 'var(--text-main)', fontSize: '1.2rem' }}>Módulo Não Parametrizado</h3>
                <p className="text-dim" style={{ maxWidth: '400px', lineHeight: 1.5, margin: 0 }}>
                  A documentação para scripts de {activeSubTab} ainda não foi listada no painel principal ou nenhum script foi adicionado à Whitelist de Automadores desta Engine.
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
          maxHeight: '400px',
          display: 'flex',
          flexDirection: 'column'
        }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1rem' }}>
            <h4 style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', color: 'var(--text-dim)', margin: 0, fontSize: '0.8rem', textTransform: 'uppercase', letterSpacing: '1px' }}>
              <Terminal size={14}/> System Console
            </h4>
            
            {/* Status Indicator inside Terminal */}
             <div style={{ display: 'flex', gap: '0.8rem', alignItems: 'center' }}>
               {status === 'loading' && <span style={{ color: 'var(--accent-glow)', fontSize: '0.8rem', display: 'flex', alignItems: 'center', gap: '0.4rem' }}><Loader2 size={12} className="spin"/> Aguardando...</span>}
               {status === 'success' && <span style={{ color: 'var(--success)', fontSize: '0.8rem', display: 'flex', alignItems: 'center', gap: '0.4rem' }}><CheckCircle size={12}/> Sucesso</span>}
               {status === 'error' && <span style={{ color: 'var(--danger)', fontSize: '0.8rem', display: 'flex', alignItems: 'center', gap: '0.4rem' }}><AlertCircle size={12}/> Falhou</span>}
               <button onClick={() => {setLogs(''); setStatus('idle')}} style={{ background: 'transparent', border: '1px solid var(--glass-border)', color: 'var(--text-dim)', fontSize: '0.7rem', padding: '0.2rem 0.5rem', borderRadius: '4px', cursor: 'pointer' }}>Clear</button>
             </div>
          </div>
          
          <pre style={{
            margin: 0,
            whiteSpace: 'pre-wrap',
            wordWrap: 'break-word',
            color: '#1beaa2', /* Console Green */
            fontFamily: '"Fira Code", "Courier New", Courier, monospace',
            fontSize: '0.85rem',
            lineHeight: 1.6,
            overflowY: 'auto',
            flex: 1,
            paddingRight: '1rem'
          }}>
            {logs || '> Ghost Nodes Supervisor Standby...\n> Selecione um script de uma Categoria para engatar...'}
          </pre>
      </div>

    </div>
  );
}

import unittest
from unittest.mock import patch, MagicMock
import os
import sys

# Ajustando o path para importar o self_healing da pasta agents
ROOT_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
AGENTS_DIR = os.path.join(ROOT_DIR, "agents")
sys.path.insert(0, AGENTS_DIR)

import self_healing

class TestSelfHealingNetwork(unittest.TestCase):

    @patch('self_healing.subprocess.check_output')
    def test_check_interface_up(self, mock_check_output):
        # Configurar mock para simular que a "br0" está UP
        mock_check_output.return_value = b"3: br0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP mode DEFAULT group default qlen 1000"
        
        result = self_healing.check_interface("br0")
        self.assertTrue(result)
        mock_check_output.assert_called_with(["ip", "link", "show", "br0"], stderr=-3) # -3 means subprocess.DEVNULL

    @patch('self_healing.subprocess.check_output')
    def test_check_interface_down(self, mock_check_output):
        # Configurar mock para simular que a "wlan0" está DOWN
        mock_check_output.return_value = b"2: wlan0: <BROADCAST,MULTICAST> mtu 1500 qdisc noop state DOWN mode DEFAULT group default qlen 1000"
        
        result = self_healing.check_interface("wlan0")
        self.assertFalse(result)

    @patch('self_healing.subprocess.check_output')
    def test_check_gateway_exists(self, mock_check_output):
        # Simular uma tabela de rotas saudável do OrangePi
        mock_check_output.return_value = b"default via 192.168.15.1 dev wlan1 proto dhcp src 192.168.15.10 metric 100 \n10.21.21.0/24 dev br0 proto kernel scope link src 10.21.21.1"
        
        result = self_healing.check_gateway()
        self.assertTrue(result)

    @patch('self_healing.subprocess.check_output')
    def test_check_gateway_missing(self, mock_check_output):
        # Simular ausência de rota default
        mock_check_output.return_value = b"10.21.21.0/24 dev br0 proto kernel scope link src 10.21.21.1"
        
        result = self_healing.check_gateway()
        self.assertFalse(result)

    @patch('self_healing.call_fixer')
    @patch('self_healing.check_gateway')
    @patch('self_healing.check_interface')
    def test_scan_health_interface_down_triggers_fixer(self, mock_check_interface, mock_check_gateway, mock_call_fixer):
        # Simular que a segunda interface essencial (wlan0) está down
        # CRITICAL_IFACES = ["br0", "wlan0"]
        mock_check_interface.side_effect = [True, False]
        
        self_healing.scan_health()
        
        # O call_fixer deve ter sido disparado para a rede e a varredura interrompida (return)
        mock_call_fixer.assert_called_once_with("fix_network", "wlan0")
        mock_check_gateway.assert_not_called()

    @patch('self_healing.call_fixer')
    @patch('self_healing.ping_container')
    @patch('self_healing.check_gateway')
    @patch('self_healing.check_interface')
    def test_scan_health_gateway_down_triggers_fixer(self, mock_check_interface, mock_check_gateway, mock_ping_container, mock_call_fixer):
        # Simular redes up mas gateway down
        mock_check_interface.return_value = True
        mock_check_gateway.return_value = False
        
        self_healing.scan_health()
        
        # call_fixer aciona o script de rota e segue para checar dockers
        mock_call_fixer.assert_any_call("fix_gateway", "default")
        mock_ping_container.assert_called()

if __name__ == '__main__':
    unittest.main()

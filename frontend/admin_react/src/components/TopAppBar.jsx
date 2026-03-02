import React from 'react';
import { Bell, Search, LogOut } from 'lucide-react';
import { useNavigate } from 'react-router-dom';

export default function TopAppBar() {
    const navigate = useNavigate();

    const handleLogout = () => {
        localStorage.removeItem('adminToken');
        navigate('/login');
    };

    return (
        <header style={{ height: '72px', backgroundColor: 'var(--surface)', borderBottom: '1px solid #E2E8F0', display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '0 24px' }}>
            <div style={{ display: 'flex', alignItems: 'center', backgroundColor: 'var(--background)', padding: '8px 16px', borderRadius: '8px', width: '320px' }}>
                <Search size={18} color="var(--text-muted)" />
                <input
                    type="text"
                    placeholder="Search applications, borrowers..."
                    style={{ border: 'none', backgroundColor: 'transparent', padding: '0 8px', outline: 'none', width: '100%' }}
                />
            </div>

            <div style={{ display: 'flex', alignItems: 'center', gap: '24px' }}>
                <button style={{ background: 'none', border: 'none', cursor: 'pointer', position: 'relative', color: 'var(--text-muted)' }}>
                    <Bell size={20} />
                    <span style={{ position: 'absolute', top: '-4px', right: '-4px', width: '8px', height: '8px', backgroundColor: 'var(--accent)', borderRadius: '50%' }}></span>
                </button>

                <button onClick={handleLogout} style={{ display: 'flex', alignItems: 'center', gap: '8px', background: 'none', border: 'none', color: 'var(--error)', fontWeight: '500', cursor: 'pointer' }}>
                    <LogOut size={18} />
                    Logout
                </button>
            </div>
        </header>
    );
}

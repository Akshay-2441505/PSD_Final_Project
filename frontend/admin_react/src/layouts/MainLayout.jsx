import React from 'react';
import { Outlet } from 'react-router-dom';
import Sidebar from '../components/Sidebar';
import TopAppBar from '../components/TopAppBar';

export default function MainLayout() {
    return (
        <div style={{ display: 'flex', minHeight: '100vh', backgroundColor: 'var(--background)' }}>
            <Sidebar />
            <div style={{ flex: 1, display: 'flex', flexDirection: 'column', overflow: 'hidden' }}>
                <TopAppBar />
                <main style={{ flex: 1, overflowY: 'auto', padding: '24px' }}>
                    <Outlet />
                </main>
            </div>
        </div>
    );
}

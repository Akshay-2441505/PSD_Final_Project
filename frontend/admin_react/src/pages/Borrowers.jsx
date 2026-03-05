import React, { useState, useEffect } from 'react';
import gsap from 'gsap';
import api from '../core/api';
import { Search, MoreVertical, CreditCard, Mail, Phone, ExternalLink, UsersRound } from 'lucide-react';

export default function Borrowers() {
    const [borrowers, setBorrowers] = useState([]);
    const [loading, setLoading] = useState(true);
    const [searchTerm, setSearchTerm] = useState('');

    useEffect(() => {
        const fetchBorrowers = async () => {
            try {
                const res = await api.get('/admin/applications');

                // Group by business_id (unique per borrower)
                const uniqueUsers = {};
                res.data.forEach(app => {
                    const key = app.business_id || app.app_id;
                    if (!uniqueUsers[key]) {
                        uniqueUsers[key] = {
                            id: app.business_id || app.app_id,
                            shortId: (app.business_id || app.app_id || '').toString().slice(-8),
                            name: app.legal_name || app.owner_name || 'Unknown Business',
                            ownerName: app.owner_name || '',
                            email: app.email || '—',
                            phone: app.phone || '—',
                            totalDisbursed: app.status === 'APPROVED' ? (app.requested_amount || 0) : 0,
                            activeLoans: app.status === 'APPROVED' ? 1 : 0,
                            riskScore: app.risk_score,
                            joinDate: new Date(app.created_at || Date.now()).toLocaleDateString('en-IN'),
                        };
                    } else {
                        if (app.status === 'APPROVED') {
                            uniqueUsers[key].totalDisbursed += (app.requested_amount || 0);
                            uniqueUsers[key].activeLoans += 1;
                        }
                    }
                });

                setBorrowers(Object.values(uniqueUsers));
            } catch (err) {
                console.error("Failed to fetch borrowers", err);
            } finally {
                setLoading(false);
            }
        };

        fetchBorrowers();
    }, []);

    useEffect(() => {
        if (!loading && borrowers.length > 0) {
            gsap.fromTo('.borrower-row',
                { y: 20, opacity: 0 },
                { y: 0, opacity: 1, duration: 0.4, stagger: 0.05, ease: 'power2.out' }
            );
        }
    }, [loading, borrowers]);

    const filteredBorrowers = borrowers.filter(b =>
        b.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
        b.email.toLowerCase().includes(searchTerm.toLowerCase())
    );

    if (loading) {
        return (
            <div style={{ display: 'flex', flexDirection: 'column', gap: '24px', animation: 'fadeIn 0.5s ease-out' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                    <div>
                        <div className="skeleton" style={{ width: '200px', height: '28px', marginBottom: '8px' }}></div>
                        <div className="skeleton" style={{ width: '300px', height: '16px' }}></div>
                    </div>
                </div>
                <div style={{ background: 'white', borderRadius: '16px', overflow: 'hidden', border: '1px solid var(--border-color)', padding: '24px', display: 'flex', flexDirection: 'column', gap: '16px' }}>
                    {[1, 2, 3, 4, 5].map(i => (
                        <div key={i} className="skeleton" style={{ width: '100%', height: '64px', borderRadius: '8px' }}></div>
                    ))}
                </div>
            </div>
        );
    }

    return (
        <div style={{
            animation: 'fadeIn 0.5s ease-out',
            display: 'flex',
            flexDirection: 'column',
            gap: '24px'
        }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <div>
                    <h1 style={{ fontSize: '24px', fontWeight: '600', color: 'var(--text-primary)', marginBottom: '8px' }}>Borrowers Directory</h1>
                    <p style={{ color: 'var(--text-secondary)', fontSize: '14px' }}>Manage customer relationships and lifetime loan portfolios.</p>
                </div>

                <div style={{
                    display: 'flex',
                    alignItems: 'center',
                    background: 'white',
                    padding: '8px 16px',
                    borderRadius: '8px',
                    border: '1px solid var(--border-color)',
                    width: '300px'
                }}>
                    <Search size={18} color="var(--text-secondary)" style={{ marginRight: '8px' }} />
                    <input
                        type="text"
                        placeholder="Search borrowers..."
                        style={{ border: 'none', outline: 'none', width: '100%', fontSize: '14px' }}
                        value={searchTerm}
                        onChange={(e) => setSearchTerm(e.target.value)}
                    />
                </div>
            </div>

            <div style={{
                background: 'white',
                borderRadius: '16px',
                border: '1px solid var(--border-color)',
                overflow: 'hidden',
                boxShadow: 'var(--shadow-sm)'
            }}>
                <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left' }}>
                    <thead>
                        <tr style={{ background: '#f8fafc', borderBottom: '1px solid var(--border-color)' }}>
                            <th style={{ padding: '16px 24px', color: 'var(--text-secondary)', fontSize: '12px', textTransform: 'uppercase', letterSpacing: '0.05em' }}>Business/Owner</th>
                            <th style={{ padding: '16px 24px', color: 'var(--text-secondary)', fontSize: '12px', textTransform: 'uppercase', letterSpacing: '0.05em' }}>Contact Info</th>
                            <th style={{ padding: '16px 24px', color: 'var(--text-secondary)', fontSize: '12px', textTransform: 'uppercase', letterSpacing: '0.05em' }}>Portfolio Health</th>
                            <th style={{ padding: '16px 24px', color: 'var(--text-secondary)', fontSize: '12px', textTransform: 'uppercase', letterSpacing: '0.05em' }}>Net Exposure</th>
                            <th style={{ padding: '16px 24px', color: 'var(--text-secondary)', fontSize: '12px', textTransform: 'uppercase', letterSpacing: '0.05em' }}>Joined</th>
                            <th style={{ padding: '16px 24px', textAlign: 'center' }}></th>
                        </tr>
                    </thead>
                    <tbody>
                        {filteredBorrowers.map((borrower) => (
                            <tr key={borrower.id} className="borrower-row" style={{ borderBottom: '1px solid var(--border-color)', transition: 'background 0.2s' }}
                                onMouseEnter={(e) => e.currentTarget.style.backgroundColor = '#f8fafc'}
                                onMouseLeave={(e) => e.currentTarget.style.backgroundColor = 'transparent'}
                            >
                                <td style={{ padding: '16px 24px' }}>
                                    <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                                        <div style={{
                                            width: '40px',
                                            height: '40px',
                                            borderRadius: '8px',
                                            background: 'var(--primary-color)',
                                            color: 'white',
                                            display: 'flex',
                                            alignItems: 'center',
                                            justifyContent: 'center',
                                            fontWeight: '600',
                                            fontSize: '16px'
                                        }}>
                                            {borrower.name.charAt(0)}
                                        </div>
                                        <div>
                                            <p style={{ fontWeight: '600', color: 'var(--text-primary)', marginBottom: '4px' }}>{borrower.name}</p>
                                            <p style={{ fontSize: '12px', color: 'var(--text-secondary)' }}>ID: {borrower.id}</p>
                                        </div>
                                    </div>
                                </td>
                                <td style={{ padding: '16px 24px' }}>
                                    <div style={{ display: 'flex', flexDirection: 'column', gap: '6px' }}>
                                        <div style={{ display: 'flex', alignItems: 'center', gap: '6px', fontSize: '13px', color: 'var(--text-secondary)' }}>
                                            <Mail size={14} /> {borrower.email}
                                        </div>
                                        <div style={{ display: 'flex', alignItems: 'center', gap: '6px', fontSize: '13px', color: 'var(--text-secondary)' }}>
                                            <Phone size={14} /> {borrower.phone}
                                        </div>
                                    </div>
                                </td>
                                <td style={{ padding: '16px 24px' }}>
                                    <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                                        <div style={{
                                            width: '8px',
                                            height: '8px',
                                            borderRadius: '50%',
                                            background: borrower.riskScore > 70 ? 'var(--success-color)' : (borrower.riskScore > 40 ? 'var(--warning-color)' : 'var(--danger-color)')
                                        }}></div>
                                        <span style={{ fontSize: '14px', fontWeight: '500', color: 'var(--text-primary)' }}>Risk: {borrower.riskScore}/100</span>
                                    </div>
                                </td>
                                <td style={{ padding: '16px 24px' }}>
                                    <p style={{ fontWeight: '600', color: 'var(--text-primary)', marginBottom: '4px' }}>₹ {borrower.totalDisbursed.toLocaleString()}</p>
                                    <p style={{ fontSize: '12px', color: 'var(--text-secondary)' }}>{borrower.activeLoans} Active Loans</p>
                                </td>
                                <td style={{ padding: '16px 24px', fontSize: '14px', color: 'var(--text-secondary)' }}>
                                    {borrower.joinDate}
                                </td>
                                <td style={{ padding: '16px 24px', textAlign: 'center' }}>
                                    <button style={{
                                        background: 'transparent',
                                        border: 'none',
                                        cursor: 'pointer',
                                        color: 'var(--text-secondary)',
                                        padding: '4px'
                                    }}>
                                        <ExternalLink size={18} />
                                    </button>
                                </td>
                            </tr>
                        ))}
                        {filteredBorrowers.length === 0 && (
                            <tr>
                                <td colSpan="6" style={{ padding: '64px', textAlign: 'center' }}>
                                    <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center' }}>
                                        <div style={{ backgroundColor: '#F1F5F9', padding: '20px', borderRadius: '50%', marginBottom: '16px' }}>
                                            <UsersRound size={40} color="var(--text-muted)" />
                                        </div>
                                        <p style={{ margin: 0, fontWeight: '600', color: 'var(--text-dark)', fontSize: '1.2rem' }}>No Borrowers Found</p>
                                        <p style={{ margin: '8px 0 0 0', color: 'var(--text-muted)', fontSize: '0.9rem' }}>We couldn't find any business entities matching your search.</p>
                                    </div>
                                </td>
                            </tr>
                        )}
                    </tbody>
                </table>
            </div>
        </div>
    );
}

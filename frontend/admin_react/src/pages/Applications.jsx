import React, { useEffect, useRef, useState } from 'react';
import gsap from 'gsap';
import api from '../core/api';
import { MoreVertical, CheckCircle, XCircle, Clock, Inbox } from 'lucide-react';

export default function Applications() {
    const containerRef = useRef(null);
    const [applications, setApplications] = useState([]);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        const fetchApps = async () => {
            try {
                const res = await api.get('/admin/applications');
                setApplications(res.data);
            } catch (err) {
                console.error("Failed to fetch applications", err);
            } finally {
                setLoading(false);
            }
        };
        fetchApps();
    }, []);

    useEffect(() => {
        if (!loading) {
            const ctx = gsap.context(() => {
                gsap.fromTo('.kanban-col',
                    { y: 30, opacity: 0 },
                    { y: 0, opacity: 1, duration: 0.6, stagger: 0.1, ease: 'power2.out' }
                );
                gsap.fromTo('.app-card',
                    { scale: 0.95, opacity: 0 },
                    { scale: 1, opacity: 1, duration: 0.4, stagger: 0.05, ease: 'back.out(1.2)', delay: 0.3 }
                );
            }, containerRef);
            return () => ctx.revert();
        }
    }, [loading, applications]);

    const columns = [
        { id: 'PENDING', title: 'Pending Review', color: 'var(--warning)', icon: Clock },
        { id: 'APPROVED', title: 'Approved', color: 'var(--success)', icon: CheckCircle },
        { id: 'REJECTED', title: 'Rejected', color: 'var(--error)', icon: XCircle },
    ];

    const formatCurrency = (val) => new Intl.NumberFormat('en-IN', { style: 'currency', currency: 'INR', maximumFractionDigits: 0 }).format(val);

    return (
        <div ref={containerRef} style={{ display: 'flex', flexDirection: 'column', height: '100%', gap: '24px' }}>
            <div>
                <h1 style={{ margin: '0 0 8px 0', fontSize: '1.8rem' }}>Loan Applications</h1>
                <p style={{ margin: 0, color: 'var(--text-muted)' }}>Manage and review MSME loan requests.</p>
            </div>

            {loading ? (
                <div style={{ display: 'flex', gap: '24px', overflowX: 'auto', paddingBottom: '16px', flex: 1 }}>
                    {columns.map(col => (
                        <div key={col.id} className="card kanban-col" style={{ flex: '0 0 320px', backgroundColor: '#F8FAFC', padding: '16px', display: 'flex', flexDirection: 'column', gap: '16px', border: 'none', boxShadow: 'none' }}>
                            <div className="skeleton" style={{ width: '140px', height: '24px', borderRadius: '4px' }}></div>
                            <div className="skeleton" style={{ height: '140px', width: '100%', borderRadius: '12px' }}></div>
                            <div className="skeleton" style={{ height: '140px', width: '100%', borderRadius: '12px' }}></div>
                        </div>
                    ))}
                </div>
            ) : (
                <div style={{ display: 'flex', gap: '24px', overflowX: 'auto', paddingBottom: '16px', flex: 1 }}>
                    {columns.map(col => {
                        const columnApps = applications.filter(a => a.status === col.id);
                        return (
                            <div key={col.id} className="kanban-col" style={{ flex: '0 0 320px', display: 'flex', flexDirection: 'column', gap: '16px', backgroundColor: 'rgba(244, 247, 250, 0.5)', padding: '16px', borderRadius: '16px', border: '1px solid #E2E8F0' }}>
                                <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '8px' }}>
                                    <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                                        <col.icon size={18} color={col.color} />
                                        <h3 style={{ margin: 0, fontSize: '1rem', color: 'var(--text-dark)' }}>{col.title}</h3>
                                    </div>
                                    <span style={{ backgroundColor: 'var(--surface)', padding: '2px 8px', borderRadius: '12px', fontSize: '0.8rem', fontWeight: '600', color: 'var(--text-muted)', border: '1px solid #E2E8F0' }}>
                                        {columnApps.length}
                                    </span>
                                </div>

                                <div style={{ display: 'flex', flexDirection: 'column', gap: '12px', overflowY: 'auto', flex: 1, paddingRight: '4px' }}>
                                    {columnApps.map(app => (
                                        <div key={app.id} className="card app-card"
                                            onClick={() => window.location.href = `/applications/${app.id}`}
                                            style={{ padding: '16px', cursor: 'pointer', transition: 'transform 0.2s, box-shadow 0.2s' }}
                                            onMouseEnter={(e) => { e.currentTarget.style.transform = 'translateY(-2px)'; e.currentTarget.style.boxShadow = '0 10px 15px -3px rgba(0,0,0,0.1)'; }}
                                            onMouseLeave={(e) => { e.currentTarget.style.transform = 'translateY(0)'; e.currentTarget.style.boxShadow = '0 4px 6px -1px rgba(0,0,0,0.05)'; }}>

                                            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '12px' }}>
                                                <div>
                                                    <p style={{ margin: 0, fontWeight: '600', color: 'var(--text-dark)' }}>{app.owner_name}</p>
                                                    <p style={{ margin: 0, fontSize: '0.8rem', color: 'var(--text-muted)' }}>{app.legal_name || 'Business Name'}</p>
                                                </div>
                                                <button style={{ background: 'none', border: 'none', color: 'var(--text-muted)', cursor: 'pointer' }}>
                                                    <MoreVertical size={16} />
                                                </button>
                                            </div>

                                            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginTop: '16px', paddingTop: '12px', borderTop: '1px solid #F1F5F9' }}>
                                                <div>
                                                    <p style={{ margin: 0, fontSize: '0.75rem', color: 'var(--text-muted)', textTransform: 'uppercase', letterSpacing: '0.5px' }}>Amount</p>
                                                    <p style={{ margin: 0, fontWeight: '600', color: 'var(--primary)', fontSize: '0.95rem' }}>{formatCurrency(app.amount)}</p>
                                                </div>
                                                <div style={{ textAlign: 'right' }}>
                                                    <p style={{ margin: 0, fontSize: '0.75rem', color: 'var(--text-muted)', textTransform: 'uppercase', letterSpacing: '0.5px' }}>Score</p>
                                                    <p style={{ margin: 0, fontWeight: 'bold', color: app.risk_score > 70 ? 'var(--success)' : app.risk_score > 40 ? 'var(--warning)' : 'var(--error)' }}>
                                                        {app.risk_score}/100
                                                    </p>
                                                </div>
                                            </div>
                                        </div>
                                    ))}
                                    {columnApps.length === 0 && (
                                        <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', padding: '32px 24px', textAlign: 'center', border: '1px dashed #CBD5E1', borderRadius: '12px', backgroundColor: 'var(--surface)' }}>
                                            <div style={{ backgroundColor: '#F1F5F9', padding: '16px', borderRadius: '50%', marginBottom: '16px' }}>
                                                <Inbox size={28} color="var(--text-muted)" />
                                            </div>
                                            <p style={{ margin: 0, fontWeight: '500', color: 'var(--text-dark)' }}>No applications</p>
                                            <p style={{ margin: '4px 0 0 0', fontSize: '0.85rem', color: 'var(--text-muted)' }}>This queue is currently empty.</p>
                                        </div>
                                    )}
                                </div>
                            </div>
                        );
                    })}
                </div>
            )}
        </div>
    );
}

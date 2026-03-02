import React, { useEffect, useRef, useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import gsap from 'gsap';
import { Line } from 'react-chartjs-2';
import api from '../core/api';
import { ArrowLeft, User, Building2, MapPin, Briefcase, FileText, CheckCircle, XCircle } from 'lucide-react';

export default function ApplicationDetail() {
    const { id } = useParams();
    const navigate = useNavigate();
    const containerRef = useRef(null);
    const [app, setApp] = useState(null);
    const [loading, setLoading] = useState(true);
    const [submitting, setSubmitting] = useState(false);

    useEffect(() => {
        const fetchDetail = async () => {
            try {
                const res = await api.get(`/admin/applications/${id}`);
                setApp(res.data);
            } catch (err) {
                console.error("Failed to fetch application", err);
            } finally {
                setLoading(false);
            }
        };
        fetchDetail();
    }, [id]);

    useEffect(() => {
        if (!loading && app) {
            const ctx = gsap.context(() => {
                gsap.fromTo('.anim-item',
                    { y: 20, opacity: 0 },
                    { y: 0, opacity: 1, duration: 0.5, stagger: 0.05, ease: 'power2.out' }
                );
            }, containerRef);
            return () => ctx.revert();
        }
    }, [loading, app]);

    const handleAction = async (status) => {
        setSubmitting(true);
        try {
            if (status === 'APPROVED') {
                const payload = new URLSearchParams();
                payload.append('interest_rate', '12.5'); // Default values for demo
                payload.append('repayment_tenure', '12');

                await api.post(`/admin/applications/${id}/approve`, payload, {
                    headers: { 'Content-Type': 'application/x-www-form-urlencoded' }
                });
            } else if (status === 'REJECTED') {
                await api.post(`/admin/applications/${id}/reject?reason=${encodeURIComponent('Credit criteria not met')}`);
            }
            // Re-fetch
            const res = await api.get(`/admin/applications/${id}`);
            setApp(res.data);
        } catch (err) {
            console.error(`Failed to ${status.toLowerCase()} app`, err);
        } finally {
            setSubmitting(false);
        }
    };

    const formatCurrency = (val) => new Intl.NumberFormat('en-IN', { style: 'currency', currency: 'INR', maximumFractionDigits: 0 }).format(val);

    if (loading) return <div style={{ padding: '48px', textAlign: 'center' }}>Loading application details...</div>;
    if (!app) return <div style={{ padding: '48px', textAlign: 'center' }}>Application not found</div>;

    const getStatusColor = (status) => {
        switch (status) {
            case 'APPROVED': return 'var(--success)';
            case 'REJECTED': return 'var(--error)';
            default: return 'var(--warning)';
        }
    };

    // Mock financial trend data for the chart
    const lineData = {
        labels: ['6 Months Ago', '5 Months Ago', '4 Months Ago', '3 Months Ago', '2 Months Ago', 'Last Month'],
        datasets: [
            {
                label: 'Monthly Revenue',
                data: [app.annual_turnover / 12 * 0.9, app.annual_turnover / 12 * 0.95, app.annual_turnover / 12, app.annual_turnover / 12 * 1.05, app.annual_turnover / 12 * 1.1, app.annual_turnover / 12 * 1.02],
                borderColor: 'var(--primary)',
                backgroundColor: 'rgba(42, 75, 155, 0.1)',
                tension: 0.4,
                fill: true,
            },
            {
                label: 'Monthly Expenses',
                data: [(app.annual_turnover - app.annual_profit) / 12, (app.annual_turnover - app.annual_profit) / 12 * 1.02, (app.annual_turnover - app.annual_profit) / 12, (app.annual_turnover - app.annual_profit) / 12 * 1.05, (app.annual_turnover - app.annual_profit) / 12 * 0.95, (app.annual_turnover - app.annual_profit) / 12],
                borderColor: 'var(--error)',
                backgroundColor: 'rgba(239, 68, 68, 0.05)',
                tension: 0.4,
                fill: true,
            }
        ],
    };

    return (
        <div ref={containerRef} style={{ display: 'flex', flexDirection: 'column', gap: '24px' }}>

            {/* Header */}
            <div className="anim-item" style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between', borderBottom: '1px solid #E2E8F0', paddingBottom: '24px' }}>
                <div>
                    <button
                        onClick={() => navigate('/applications')}
                        style={{ display: 'flex', alignItems: 'center', gap: '8px', background: 'none', color: 'var(--text-muted)', marginBottom: '16px' }}
                    >
                        <ArrowLeft size={16} /> Back to Applications
                    </button>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
                        <h1 style={{ margin: 0, fontSize: '2rem' }}>{app.owner_name}</h1>
                        <span style={{
                            backgroundColor: `${getStatusColor(app.status)}15`,
                            color: getStatusColor(app.status),
                            padding: '6px 12px',
                            borderRadius: '20px',
                            fontSize: '0.85rem',
                            fontWeight: '600',
                            border: `1px solid ${getStatusColor(app.status)}40`
                        }}>
                            {app.status}
                        </span>
                    </div>
                    <p style={{ margin: '8px 0 0 0', color: 'var(--text-muted)', display: 'flex', alignItems: 'center', gap: '8px' }}>
                        <Building2 size={16} /> {app.legal_name || 'Business Name not provided'} &bull; Applied: {new Date(app.created_at).toLocaleDateString()}
                    </p>
                </div>

                {app.status === 'PENDING' && (
                    <div style={{ display: 'flex', gap: '12px' }}>
                        <button
                            onClick={() => handleAction('REJECTED')}
                            disabled={submitting}
                            style={{ padding: '10px 20px', backgroundColor: 'white', border: '1px solid var(--error)', color: 'var(--error)' }}
                        >
                            <XCircle size={18} style={{ marginRight: '8px', verticalAlign: 'middle' }} /> Reject
                        </button>
                        <button
                            onClick={() => handleAction('APPROVED')}
                            disabled={submitting}
                            className="btn-primary"
                        >
                            <CheckCircle size={18} style={{ marginRight: '8px', verticalAlign: 'middle' }} /> Approve Loan
                        </button>
                    </div>
                )}
            </div>

            <div style={{ display: 'grid', gridTemplateColumns: '2fr 1fr', gap: '24px' }}>

                {/* Left Column */}
                <div style={{ display: 'flex', flexDirection: 'column', gap: '24px' }}>

                    {/* Key Metrics */}
                    <div className="anim-item" style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '16px' }}>
                        <div className="card" style={{ padding: '24px', borderLeft: '4px solid var(--primary)' }}>
                            <p style={{ margin: '0 0 8px 0', fontSize: '0.9rem', color: 'var(--text-muted)', textTransform: 'uppercase' }}>Requested Amount</p>
                            <h2 style={{ margin: 0, fontSize: '1.8rem', color: 'var(--primary)' }}>{formatCurrency(app.amount)}</h2>
                            <p style={{ margin: '8px 0 0 0', fontSize: '0.85rem', color: 'var(--text-muted)' }}>Over {app.repayment_tenure || 12} months</p>
                        </div>

                        <div className="card" style={{ padding: '24px', borderLeft: `4px solid ${app.risk_score > 70 ? 'var(--success)' : app.risk_score > 40 ? 'var(--warning)' : 'var(--error)'}` }}>
                            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                                <div>
                                    <p style={{ margin: '0 0 8px 0', fontSize: '0.9rem', color: 'var(--text-muted)', textTransform: 'uppercase' }}>Risk Score</p>
                                    <h2 style={{ margin: 0, fontSize: '1.8rem', color: 'var(--text-dark)' }}>{app.risk_score} <span style={{ fontSize: '1rem', color: 'var(--text-muted)' }}>/100</span></h2>
                                </div>
                                <div style={{ width: '48px', height: '48px', borderRadius: '50%', backgroundColor: `${app.risk_score > 70 ? 'var(--success)' : app.risk_score > 40 ? 'var(--warning)' : 'var(--error)'}15`, display: 'flex', alignItems: 'center', justifyItems: 'center', color: app.risk_score > 70 ? 'var(--success)' : app.risk_score > 40 ? 'var(--warning)' : 'var(--error)' }}>
                                    {app.risk_score > 70 ? <CheckCircle size={24} style={{ margin: 'auto' }} /> : <FileText size={24} style={{ margin: 'auto' }} />}
                                </div>
                            </div>
                        </div>
                    </div>

                    {/* Risk Score Breakdown */}
                    {app.score_breakdown && (
                        <div className="card anim-item" style={{ padding: '24px' }}>
                            <h3 style={{ marginBottom: '20px', display: 'flex', alignItems: 'center', gap: '8px' }}><Activity size={20} color="var(--primary)" /> Risk Score Breakdown</h3>
                            <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left' }}>
                                <thead>
                                    <tr style={{ borderBottom: '1px solid #E2E8F0', color: 'var(--text-muted)', fontSize: '0.9rem' }}>
                                        <th style={{ padding: '12px 8px' }}>Category</th>
                                        <th style={{ padding: '12px 8px' }}>Description</th>
                                        <th style={{ padding: '12px 8px', textAlign: 'right' }}>Score Impact</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    {app.score_breakdown.map((item, idx) => (
                                        <tr key={idx} style={{ borderBottom: '1px solid #F1F5F9' }}>
                                            <td style={{ padding: '16px 8px', fontWeight: '500' }}>{item.category}</td>
                                            <td style={{ padding: '16px 8px', color: 'var(--text-muted)', fontSize: '0.9rem' }}>{item.reason}</td>
                                            <td style={{ padding: '16px 8px', textAlign: 'right', fontWeight: 'bold', color: item.impact > 0 ? 'var(--success)' : 'var(--error)' }}>
                                                {item.impact > 0 ? '+' : ''}{item.impact}
                                            </td>
                                        </tr>
                                    ))}
                                    <tr style={{ backgroundColor: 'var(--background)' }}>
                                        <td colSpan="2" style={{ padding: '16px 8px', fontWeight: 'bold', textAlign: 'right' }}>Total Final Score</td>
                                        <td style={{ padding: '16px 8px', textAlign: 'right', fontWeight: 'bold', fontSize: '1.1rem' }}>{app.risk_score}</td>
                                    </tr>
                                </tbody>
                            </table>
                        </div>
                    )}

                    {/* Financials Chart */}
                    <div className="card anim-item" style={{ padding: '24px' }}>
                        <h3 style={{ marginBottom: '24px', display: 'flex', alignItems: 'center', gap: '8px' }}><Briefcase size={20} color="var(--primary)" /> Financial Trend (Simulated)</h3>
                        <div style={{ height: '300px' }}>
                            <Line data={lineData} options={{ responsive: true, maintainAspectRatio: false }} />
                        </div>
                    </div>
                </div>

                {/* Right Column */}
                <div style={{ display: 'flex', flexDirection: 'column', gap: '24px' }}>

                    {/* Business Information */}
                    <div className="card anim-item" style={{ padding: '24px' }}>
                        <h3 style={{ marginBottom: '20px', fontSize: '1.2rem', paddingBottom: '12px', borderBottom: '1px solid #E2E8F0' }}>Business Profile</h3>

                        <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
                            <div>
                                <p style={{ margin: '0 0 4px 0', fontSize: '0.85rem', color: 'var(--text-muted)' }}>Business Type</p>
                                <p style={{ margin: 0, fontWeight: '500' }}>{app.business_type}</p>
                            </div>
                            <div>
                                <p style={{ margin: '0 0 4px 0', fontSize: '0.85rem', color: 'var(--text-muted)' }}>Annual Turnover</p>
                                <p style={{ margin: 0, fontWeight: '500' }}>{formatCurrency(app.annual_turnover)}</p>
                            </div>
                            <div>
                                <p style={{ margin: '0 0 4px 0', fontSize: '0.85rem', color: 'var(--text-muted)' }}>Annual Profit</p>
                                <p style={{ margin: 0, fontWeight: '500' }}>{formatCurrency(app.annual_profit)}</p>
                            </div>
                            <div>
                                <p style={{ margin: '0 0 4px 0', fontSize: '0.85rem', color: 'var(--text-muted)' }}>Profit Margin</p>
                                <p style={{ margin: 0, fontWeight: '500', color: 'var(--success)' }}>
                                    {Math.round((app.annual_profit / app.annual_turnover) * 100)}%
                                </p>
                            </div>
                            <div>
                                <p style={{ margin: '0 0 4px 0', fontSize: '0.85rem', color: 'var(--text-muted)' }}>GSTIN</p>
                                <p style={{ margin: 0, fontWeight: '500', fontFamily: 'monospace' }}>{app.gstin || 'N/A'}</p>
                            </div>
                        </div>
                    </div>

                    {/* Contact Details */}
                    <div className="card anim-item" style={{ padding: '24px', backgroundColor: 'var(--primary)', color: 'white' }}>
                        <h3 style={{ marginBottom: '20px', fontSize: '1.2rem', color: 'white', paddingBottom: '12px', borderBottom: '1px solid rgba(255,255,255,0.2)' }}>Contact Details</h3>

                        <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
                            <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                                <User size={18} opacity={0.8} />
                                <span style={{ fontWeight: '500' }}>{app.owner_name}</span>
                            </div>
                            <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                                <MapPin size={18} opacity={0.8} />
                                <span>address@example.com <br /><span style={{ opacity: 0.8, fontSize: '0.85rem' }}>+91 9876543210</span></span>
                            </div>
                        </div>
                    </div>
                </div>

            </div>
        </div>
    );
}

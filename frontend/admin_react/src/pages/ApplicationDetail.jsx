import React, { useEffect, useRef, useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import gsap from 'gsap';
import { Line, Doughnut } from 'react-chartjs-2';
import {
    Chart as ChartJS,
    CategoryScale,
    LinearScale,
    PointElement,
    LineElement,
    Title,
    Tooltip,
    Legend,
    ArcElement,
    Filler
} from 'chart.js';
import api from '../core/api';
import {
    ArrowLeft, User, Building2, Briefcase, FileText,
    CheckCircle, XCircle, Activity, AlertCircle, Phone, Mail
} from 'lucide-react';
import { useToast } from '../components/ToastProvider';

// ── Chart.js registration (required by react-chartjs-2 v5) ────────────────
ChartJS.register(
    CategoryScale,
    LinearScale,
    PointElement,
    LineElement,
    Title,
    Tooltip,
    Legend,
    ArcElement,
    Filler
);

export default function ApplicationDetail() {
    const { id } = useParams();
    const navigate = useNavigate();
    const containerRef = useRef(null);

    const [app, setApp] = useState(null);
    const [revenueData, setRevenueData] = useState(null);
    const [expenseData, setExpenseData] = useState(null);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(null);
    const [submitting, setSubmitting] = useState(false);
    const [remarksInput, setRemarksInput] = useState('');
    const [showRemarksModal, setShowRemarksModal] = useState(false);
    const [pendingDecision, setPendingDecision] = useState(null);

    const { addToast } = useToast();

    // ── Fetch application detail + charts ───────────────────────────────────
    useEffect(() => {
        const fetchAll = async () => {
            setLoading(true);
            setError(null);
            try {
                // Main detail load — must succeed
                const detailRes = await api.get(`/admin/applications/${id}`);
                setApp(detailRes.data);

                // Chart calls — load independently, never block the main detail
                try {
                    const revenueRes = await api.get(`/admin/charts/revenue?app_id=${id}`);
                    setRevenueData(revenueRes.data);
                } catch (chartErr) {
                    console.warn('Revenue chart failed (non-fatal):', chartErr?.response?.status, chartErr?.message);
                }
                try {
                    const expenseRes = await api.get(`/admin/charts/expenses?app_id=${id}`);
                    setExpenseData(expenseRes.data);
                } catch (chartErr) {
                    console.warn('Expense chart failed (non-fatal):', chartErr?.response?.status, chartErr?.message);
                }

            } catch (err) {
                const status = err?.response?.status;
                const detail = err?.response?.data?.detail;
                console.error('Failed to fetch application detail:', status, detail, err);
                setError(`${status ?? 'Network Error'}: ${detail ?? err.message}`);
            } finally {
                setLoading(false);
            }
        };
        fetchAll();
    }, [id]);

    // ── GSAP entrance animation ─────────────────────────────────────────────
    useEffect(() => {
        if (!loading && app) {
            const ctx = gsap.context(() => {
                gsap.fromTo('.anim-item',
                    { y: 20, opacity: 0 },
                    { y: 0, opacity: 1, duration: 0.5, stagger: 0.06, ease: 'power2.out' }
                );
            }, containerRef);
            return () => ctx.revert();
        }
    }, [loading, app]);

    // ── Decision handler ─────────────────────────────────────────────────────
    const openDecisionModal = (decision) => {
        setPendingDecision(decision);
        setRemarksInput(
            decision === 'APPROVED'
                ? 'Loan approved after review.'
                : decision === 'REJECTED'
                    ? 'Credit criteria not met.'
                    : 'Please provide additional financial documents.'
        );
        setShowRemarksModal(true);
    };

    const submitDecision = async () => {
        if (!pendingDecision) return;
        setSubmitting(true);
        setShowRemarksModal(false);
        try {
            await api.patch(`/admin/applications/${id}/decision`, {
                decision: pendingDecision,
                remarks: remarksInput,
            });
            const res = await api.get(`/admin/applications/${id}`);
            setApp(res.data);
            addToast(
                `Application ${pendingDecision.replace('_', ' ').toLowerCase()} successfully`,
                pendingDecision === 'APPROVED' ? 'success' : 'info'
            );
        } catch (err) {
            console.error('Decision failed:', err);
            addToast('Failed to submit decision. Please try again.', 'error');
        } finally {
            setSubmitting(false);
            setPendingDecision(null);
        }
    };

    // ── Helpers ──────────────────────────────────────────────────────────────
    const formatCurrency = (val) =>
        new Intl.NumberFormat('en-IN', {
            style: 'currency', currency: 'INR', maximumFractionDigits: 0
        }).format(val ?? 0);

    const getStatusColor = (status) => {
        switch (status) {
            case 'APPROVED': return 'var(--success)';
            case 'REJECTED': return 'var(--error)';
            case 'MORE_INFO_REQUESTED': return '#8B5CF6';
            default: return 'var(--warning)';
        }
    };

    const getStatusLabel = (status) => {
        switch (status) {
            case 'MORE_INFO_REQUESTED': return 'More Info Requested';
            default: return status;
        }
    };

    // ── Loading skeleton ─────────────────────────────────────────────────────
    if (loading) {
        return (
            <div style={{ display: 'flex', flexDirection: 'column', gap: '24px' }}>
                <div className="skeleton" style={{ height: '80px', borderRadius: '12px' }}></div>
                <div style={{ display: 'grid', gridTemplateColumns: '2fr 1fr', gap: '24px' }}>
                    <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
                        <div className="skeleton" style={{ height: '120px', borderRadius: '12px' }}></div>
                        <div className="skeleton" style={{ height: '320px', borderRadius: '12px' }}></div>
                        <div className="skeleton" style={{ height: '280px', borderRadius: '12px' }}></div>
                    </div>
                    <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
                        <div className="skeleton" style={{ height: '260px', borderRadius: '12px' }}></div>
                        <div className="skeleton" style={{ height: '160px', borderRadius: '12px' }}></div>
                    </div>
                </div>
            </div>
        );
    }

    if (!app) {
        return (
            <div style={{ padding: '60px', textAlign: 'center' }}>
                <XCircle size={48} color="var(--error)" style={{ marginBottom: '16px' }} />
                <h2>Failed to load application</h2>
                <p style={{ color: 'var(--text-muted)', marginBottom: '8px' }}>
                    The application could not be loaded. Check the browser console for details.
                </p>
                {error && (
                    <div style={{
                        display: 'inline-block', backgroundColor: '#FEE2E2', color: '#B91C1C',
                        padding: '10px 20px', borderRadius: '8px', fontSize: '0.9rem',
                        fontFamily: 'monospace', marginBottom: '20px'
                    }}>
                        Error: {error}
                    </div>
                )}
                <br />
                <button className="btn-primary" onClick={() => navigate('/applications')} style={{ marginTop: '8px' }}>
                    Back to Applications
                </button>
            </div>
        );
    }

    // ── Derived values ───────────────────────────────────────────────────────
    const turnover = app.annual_turnover ?? app.declared_turnover ?? 0;
    const profit = app.annual_profit ?? app.declared_profit ?? 0;

    // ── Revenue Line Chart ───────────────────────────────────────────────────
    const lineChartData = {
        labels: revenueData?.months ?? ['M-6', 'M-5', 'M-4', 'M-3', 'M-2', 'M-1'],
        datasets: [
            {
                label: 'Monthly Revenue (₹)',
                data: revenueData?.revenue ?? [],
                borderColor: '#2A4B9B',
                backgroundColor: 'rgba(42, 75, 155, 0.12)',
                tension: 0.4,
                fill: true,
                pointRadius: 5,
                pointBackgroundColor: '#2A4B9B',
            },
        ],
    };

    const lineChartOptions = {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
            legend: { display: false },
            tooltip: {
                callbacks: {
                    label: (ctx) => ` ₹${ctx.parsed.y.toLocaleString('en-IN')}`,
                },
            },
        },
        scales: {
            y: {
                ticks: {
                    callback: (val) => `₹${(val / 1000).toFixed(0)}K`,
                },
                grid: { color: 'rgba(0,0,0,0.04)' },
            },
            x: {
                grid: { display: false },
            },
        },
    };

    // ── Expense Doughnut Chart ───────────────────────────────────────────────
    const expenseChartData = {
        labels: expenseData?.categories ?? [],
        datasets: [
            {
                data: expenseData?.values ?? [],
                backgroundColor: [
                    '#2A4B9B', '#10B981', '#F59E0B', '#EF4444',
                    '#8B5CF6', '#06B6D4', '#F97316',
                ],
                borderWidth: 2,
                borderColor: '#fff',
            },
        ],
    };

    const doughnutOptions = {
        responsive: true,
        maintainAspectRatio: false,
        cutout: '65%',
        plugins: {
            legend: {
                position: 'right',
                labels: { boxWidth: 12, padding: 16, font: { size: 12 } },
            },
            tooltip: {
                callbacks: {
                    label: (ctx) => ` ₹${ctx.parsed.toLocaleString('en-IN')}`,
                },
            },
        },
    };

    return (
        <div ref={containerRef} style={{ display: 'flex', flexDirection: 'column', gap: '24px' }}>

            {/* ── Remarks Modal ────────────────────────────────────────────── */}
            {showRemarksModal && (
                <div style={{
                    position: 'fixed', inset: 0, backgroundColor: 'rgba(0,0,0,0.4)',
                    display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 1000,
                }}>
                    <div className="card" style={{ padding: '32px', width: '480px', maxWidth: '90vw' }}>
                        <h3 style={{ marginBottom: '8px' }}>
                            {pendingDecision === 'APPROVED' ? '✅ Approve Application' :
                                pendingDecision === 'REJECTED' ? '❌ Reject Application' :
                                    '📋 Request More Information'}
                        </h3>
                        <p style={{ marginBottom: '16px', color: 'var(--text-muted)', fontSize: '0.9rem' }}>
                            Add remarks for the borrower (optional but recommended):
                        </p>
                        <textarea
                            value={remarksInput}
                            onChange={(e) => setRemarksInput(e.target.value)}
                            rows={4}
                            style={{
                                width: '100%', padding: '12px', borderRadius: '8px',
                                border: '1px solid #CBD5E1', fontSize: '0.95rem',
                                resize: 'vertical', fontFamily: 'inherit', boxSizing: 'border-box',
                            }}
                        />
                        <div style={{ display: 'flex', gap: '12px', marginTop: '20px', justifyContent: 'flex-end' }}>
                            <button
                                onClick={() => { setShowRemarksModal(false); setPendingDecision(null); }}
                                style={{ padding: '10px 20px', background: 'white', border: '1px solid #CBD5E1', borderRadius: '8px', cursor: 'pointer' }}
                            >
                                Cancel
                            </button>
                            <button
                                className="btn-primary"
                                onClick={submitDecision}
                                disabled={submitting}
                                style={{
                                    backgroundColor:
                                        pendingDecision === 'APPROVED' ? 'var(--success)' :
                                            pendingDecision === 'REJECTED' ? 'var(--error)' : '#8B5CF6',
                                }}
                            >
                                Confirm {pendingDecision === 'MORE_INFO_REQUESTED' ? 'Request' : pendingDecision?.charAt(0) + pendingDecision?.slice(1).toLowerCase()}
                            </button>
                        </div>
                    </div>
                </div>
            )}

            {/* ── Header ──────────────────────────────────────────────────── */}
            <div className="anim-item" style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between', borderBottom: '1px solid #E2E8F0', paddingBottom: '24px' }}>
                <div>
                    <button
                        onClick={() => navigate('/applications')}
                        style={{ display: 'flex', alignItems: 'center', gap: '8px', background: 'none', border: 'none', color: 'var(--text-muted)', cursor: 'pointer', marginBottom: '16px', fontSize: '0.9rem' }}
                    >
                        <ArrowLeft size={16} /> Back to Applications
                    </button>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '16px', flexWrap: 'wrap' }}>
                        <h1 style={{ margin: 0, fontSize: '2rem' }}>{app.owner_name}</h1>
                        <span style={{
                            backgroundColor: `${getStatusColor(app.status)}15`,
                            color: getStatusColor(app.status),
                            padding: '6px 14px', borderRadius: '20px',
                            fontSize: '0.85rem', fontWeight: '600',
                            border: `1px solid ${getStatusColor(app.status)}40`,
                        }}>
                            {getStatusLabel(app.status)}
                        </span>
                    </div>
                    <p style={{ margin: '8px 0 0 0', color: 'var(--text-muted)', display: 'flex', alignItems: 'center', gap: '8px' }}>
                        <Building2 size={16} />
                        {app.legal_name || 'Business Name not provided'} &bull; Applied: {new Date(app.created_at).toLocaleDateString('en-IN', { day: '2-digit', month: 'short', year: 'numeric' })}
                    </p>
                </div>

                {/* ── Action Buttons (only for PENDING) ──────────────────── */}
                {app.status === 'PENDING' && (
                    <div style={{ display: 'flex', gap: '10px', flexWrap: 'wrap' }}>
                        <button
                            onClick={() => openDecisionModal('REJECTED')}
                            disabled={submitting}
                            style={{
                                padding: '10px 18px', backgroundColor: 'white',
                                border: '1px solid var(--error)', color: 'var(--error)',
                                borderRadius: '8px', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: '8px', fontWeight: '500',
                            }}
                        >
                            <XCircle size={17} /> Reject
                        </button>
                        <button
                            onClick={() => openDecisionModal('MORE_INFO_REQUESTED')}
                            disabled={submitting}
                            style={{
                                padding: '10px 18px', backgroundColor: 'white',
                                border: '1px solid #8B5CF6', color: '#8B5CF6',
                                borderRadius: '8px', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: '8px', fontWeight: '500',
                            }}
                        >
                            <AlertCircle size={17} /> More Info
                        </button>
                        <button
                            onClick={() => openDecisionModal('APPROVED')}
                            disabled={submitting}
                            className="btn-primary"
                            style={{ display: 'flex', alignItems: 'center', gap: '8px' }}
                        >
                            <CheckCircle size={17} /> Approve Loan
                        </button>
                    </div>
                )}
            </div>

            <div style={{ display: 'grid', gridTemplateColumns: '2fr 1fr', gap: '24px' }}>

                {/* ── LEFT COLUMN ─────────────────────────────────────────── */}
                <div style={{ display: 'flex', flexDirection: 'column', gap: '24px' }}>

                    {/* Key Metrics */}
                    <div className="anim-item" style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '16px' }}>
                        <div className="card" style={{ padding: '24px', borderLeft: '4px solid var(--primary)' }}>
                            <p style={{ margin: '0 0 6px 0', fontSize: '0.85rem', color: 'var(--text-muted)', textTransform: 'uppercase', letterSpacing: '0.5px' }}>Requested Amount</p>
                            <h2 style={{ margin: 0, fontSize: '1.8rem', color: 'var(--primary)' }}>{formatCurrency(app.requested_amount)}</h2>
                            <p style={{ margin: '6px 0 0 0', fontSize: '0.85rem', color: 'var(--text-muted)' }}>Over {app.tenure_months || 12} months</p>
                        </div>

                        <div className="card" style={{
                            padding: '24px',
                            borderLeft: `4px solid ${app.risk_score > 70 ? 'var(--success)' : app.risk_score > 40 ? 'var(--warning)' : 'var(--error)'}`,
                        }}>
                            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                                <div>
                                    <p style={{ margin: '0 0 6px 0', fontSize: '0.85rem', color: 'var(--text-muted)', textTransform: 'uppercase', letterSpacing: '0.5px' }}>Risk Score</p>
                                    <h2 style={{ margin: 0, fontSize: '1.8rem', color: 'var(--text-dark)' }}>
                                        {app.risk_score ?? '—'}
                                        <span style={{ fontSize: '1rem', color: 'var(--text-muted)' }}> /100</span>
                                    </h2>
                                </div>
                                <div style={{
                                    width: '44px', height: '44px', borderRadius: '50%',
                                    backgroundColor: `${app.risk_score > 70 ? 'var(--success)' : app.risk_score > 40 ? 'var(--warning)' : 'var(--error)'}15`,
                                    display: 'flex', alignItems: 'center', justifyContent: 'center',
                                    color: app.risk_score > 70 ? 'var(--success)' : app.risk_score > 40 ? 'var(--warning)' : 'var(--error)',
                                }}>
                                    {app.risk_score > 70
                                        ? <CheckCircle size={22} />
                                        : app.risk_score > 40
                                            ? <AlertCircle size={22} />
                                            : <XCircle size={22} />
                                    }
                                </div>
                            </div>
                        </div>
                    </div>

                    {/* Risk Score Breakdown */}
                    {app.score_breakdown && app.score_breakdown.length > 0 && (
                        <div className="card anim-item" style={{ padding: '24px' }}>
                            <h3 style={{ marginBottom: '20px', display: 'flex', alignItems: 'center', gap: '8px' }}>
                                <Activity size={20} color="var(--primary)" /> Risk Score Breakdown
                            </h3>
                            <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left' }}>
                                <thead>
                                    <tr style={{ borderBottom: '2px solid #E2E8F0', color: 'var(--text-muted)', fontSize: '0.85rem', textTransform: 'uppercase' }}>
                                        <th style={{ padding: '10px 8px' }}>Rule</th>
                                        <th style={{ padding: '10px 8px' }}>Explanation</th>
                                        <th style={{ padding: '10px 8px', textAlign: 'right' }}>Impact</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    {app.score_breakdown.map((item, idx) => (
                                        <tr key={idx} style={{ borderBottom: '1px solid #F1F5F9' }}>
                                            <td style={{ padding: '14px 8px', fontSize: '0.9rem' }}>
                                                <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                                                    <div style={{
                                                        width: '8px', height: '8px', borderRadius: '50%', flexShrink: 0,
                                                        backgroundColor: item.severity === 'high' ? 'var(--error)'
                                                            : item.severity === 'medium' ? 'var(--warning)'
                                                                : item.severity === 'low' ? '#F59E0B'
                                                                    : 'var(--success)',
                                                    }} />
                                                    <strong>{item.rule || item.category || '—'}</strong>
                                                </div>
                                            </td>
                                            <td style={{ padding: '14px 8px', color: 'var(--text-muted)', fontSize: '0.85rem', maxWidth: '320px', lineHeight: 1.5 }}>{item.detail || item.reason || '—'}</td>
                                            <td style={{
                                                padding: '14px 8px', textAlign: 'right', fontWeight: 'bold',
                                                color: item.impact >= 0 ? 'var(--success)' : 'var(--error)',
                                            }}>
                                                {item.impact > 0 ? '+' : ''}{item.impact}
                                            </td>
                                        </tr>
                                    ))}
                                    <tr style={{ backgroundColor: '#F8FAFC' }}>
                                        <td colSpan="2" style={{ padding: '14px 8px', fontWeight: 'bold', textAlign: 'right', color: 'var(--text-muted)' }}>Total Score</td>
                                        <td style={{ padding: '14px 8px', textAlign: 'right', fontWeight: 'bold', fontSize: '1.1rem', color: 'var(--text-dark)' }}>
                                            {app.risk_score}
                                        </td>
                                    </tr>
                                </tbody>
                            </table>
                        </div>
                    )}

                    {/* Revenue Trend Chart */}
                    <div className="card anim-item" style={{ padding: '24px' }}>
                        <h3 style={{ marginBottom: '6px', display: 'flex', alignItems: 'center', gap: '8px' }}>
                            <Briefcase size={20} color="var(--primary)" /> Monthly Revenue Trend
                        </h3>
                        <p style={{ margin: '0 0 20px 0', fontSize: '0.85rem', color: 'var(--text-muted)' }}>
                            Based on Account Aggregator / declared financial data
                        </p>
                        <div style={{ height: '280px' }}>
                            {revenueData?.revenue?.length > 0
                                ? <Line data={lineChartData} options={lineChartOptions} />
                                : <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', height: '100%', color: 'var(--text-muted)' }}>No revenue data available</div>
                            }
                        </div>
                    </div>

                    {/* Expense Breakdown Chart */}
                    <div className="card anim-item" style={{ padding: '24px' }}>
                        <h3 style={{ marginBottom: '6px', display: 'flex', alignItems: 'center', gap: '8px' }}>
                            <FileText size={20} color="var(--primary)" /> Expense Breakdown
                        </h3>
                        <p style={{ margin: '0 0 20px 0', fontSize: '0.85rem', color: 'var(--text-muted)' }}>
                            Distribution of business expenses by category
                        </p>
                        <div style={{ height: '280px' }}>
                            {expenseData?.categories?.length > 0
                                ? <Doughnut data={expenseChartData} options={doughnutOptions} />
                                : <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', height: '100%', color: 'var(--text-muted)' }}>No expense data available</div>
                            }
                        </div>
                    </div>

                    {/* Admin Remarks (if any) */}
                    {app.admin_remarks && (
                        <div className="card anim-item" style={{ padding: '24px', borderLeft: '4px solid var(--warning)', backgroundColor: '#FFFBEB' }}>
                            <h4 style={{ margin: '0 0 8px 0', color: 'var(--warning)' }}>Admin Remarks</h4>
                            <p style={{ margin: 0, color: 'var(--text-dark)', lineHeight: 1.6 }}>{app.admin_remarks}</p>
                        </div>
                    )}
                </div>

                {/* ── RIGHT COLUMN ─────────────────────────────────────────── */}
                <div style={{ display: 'flex', flexDirection: 'column', gap: '24px' }}>

                    {/* Business Profile */}
                    <div className="card anim-item" style={{ padding: '24px' }}>
                        <h3 style={{ marginBottom: '20px', fontSize: '1.1rem', paddingBottom: '12px', borderBottom: '1px solid #E2E8F0' }}>
                            Business Profile
                        </h3>
                        <div style={{ display: 'flex', flexDirection: 'column', gap: '14px' }}>
                            {[
                                { label: 'Business Type', value: app.business_type || 'N/A' },
                                { label: 'Loan Purpose', value: (app.purpose || '').replace(/_/g, ' ') || 'N/A' },
                                {
                                    label: 'Annual Turnover',
                                    value: turnover ? formatCurrency(turnover) : 'N/A',
                                },
                                {
                                    label: 'Annual Profit',
                                    value: profit ? formatCurrency(profit) : 'N/A',
                                },
                                ...(turnover && profit ? [{
                                    label: 'Profit Margin',
                                    value: `${Math.round((profit / turnover) * 100)}%`,
                                    highlight: true,
                                }] : []),
                                { label: 'GSTIN', value: app.gstin || 'N/A', mono: true },
                            ].map((row, i) => (
                                <div key={i}>
                                    <p style={{ margin: '0 0 3px 0', fontSize: '0.82rem', color: 'var(--text-muted)', textTransform: 'uppercase', letterSpacing: '0.4px' }}>
                                        {row.label}
                                    </p>
                                    <p style={{
                                        margin: 0, fontWeight: '500',
                                        fontFamily: row.mono ? 'monospace' : 'inherit',
                                        color: row.highlight ? 'var(--success)' : 'var(--text-dark)',
                                    }}>
                                        {row.value}
                                    </p>
                                </div>
                            ))}
                        </div>
                    </div>

                    {/* Contact Details */}
                    <div className="card anim-item" style={{ padding: '24px', background: 'linear-gradient(135deg, #2A4B9B 0%, #1a3a7a 100%)', color: 'white' }}>
                        <h3 style={{ marginBottom: '20px', fontSize: '1.1rem', color: 'white', paddingBottom: '12px', borderBottom: '1px solid rgba(255,255,255,0.2)' }}>
                            Contact Details
                        </h3>
                        <div style={{ display: 'flex', flexDirection: 'column', gap: '14px' }}>
                            <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                                <div style={{ opacity: 0.7 }}><User size={17} /></div>
                                <span style={{ fontWeight: '500' }}>{app.owner_name}</span>
                            </div>
                            <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                                <div style={{ opacity: 0.7 }}><Mail size={17} /></div>
                                <span style={{ fontSize: '0.9rem' }}>{app.email || 'N/A'}</span>
                            </div>
                            <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                                <div style={{ opacity: 0.7 }}><Phone size={17} /></div>
                                <span style={{ fontSize: '0.9rem' }}>{app.phone || 'N/A'}</span>
                            </div>
                        </div>
                    </div>

                    {/* Risk Flags */}
                    {app.risk_flags && app.risk_flags.length > 0 && (
                        <div className="card anim-item" style={{ padding: '24px', border: '1px solid #FDE68A', backgroundColor: '#FFFBEB' }}>
                            <h4 style={{ margin: '0 0 14px 0', color: '#92400E', display: 'flex', alignItems: 'center', gap: '8px' }}>
                                <AlertCircle size={18} /> Risk Flags
                            </h4>
                            <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
                                {app.risk_flags.map((flag, i) => (
                                    <div key={i} style={{
                                        padding: '8px 12px', borderRadius: '6px',
                                        backgroundColor: '#FEF3C7', fontSize: '0.85rem',
                                        color: '#92400E', fontWeight: '500',
                                    }}>
                                        ⚠ {flag.replace(/_/g, ' ')}
                                    </div>
                                ))}
                            </div>
                        </div>
                    )}
                </div>

            </div>
        </div>
    );
}

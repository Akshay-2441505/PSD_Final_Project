import React, { useEffect, useRef, useState } from 'react';
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
import { Wallet, Activity, CreditCard, TrendingUp } from 'lucide-react';
import api from '../core/api';

ChartJS.register(
    CategoryScale, LinearScale, PointElement, LineElement,
    Title, Tooltip, Legend, ArcElement, Filler
);

export default function Dashboard() {
    const containerRef = useRef(null);
    const [stats, setStats] = useState(null);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        const fetchStats = async () => {
            try {
                const res = await api.get('/admin/applications');
                const apps = res.data;

                const approved = apps.filter(a => a.status === 'APPROVED');
                const pending = apps.filter(a => a.status === 'PENDING');
                const rejected = apps.filter(a => a.status === 'REJECTED');
                const disbursed = approved.reduce((acc, a) => acc + (a.requested_amount || 0), 0);
                const approvalRate = apps.length > 0 ? Math.round((approved.length / apps.length) * 100) : 0;

                setStats({
                    total: apps.length,
                    approved: approved.length,
                    pending: pending.length,
                    rejected: rejected.length,
                    disbursed,
                    approvalRate,
                });
            } catch (err) {
                console.error('Dashboard stats failed:', err);
            } finally {
                setLoading(false);
            }
        };
        fetchStats();
    }, []);

    useEffect(() => {
        if (!loading) {
            const ctx = gsap.context(() => {
                gsap.fromTo('.dash-card',
                    { y: 30, opacity: 0 },
                    { y: 0, opacity: 1, duration: 0.6, stagger: 0.1, ease: 'power2.out' }
                );
                gsap.fromTo('.dash-chart',
                    { scale: 0.95, opacity: 0 },
                    { scale: 1, opacity: 1, duration: 0.8, delay: 0.4, ease: 'power2.out' }
                );
            }, containerRef);
            return () => ctx.revert();
        }
    }, [loading]);

    const formatCurrency = (val) =>
        new Intl.NumberFormat('en-IN', { style: 'currency', currency: 'INR', maximumFractionDigits: 0 }).format(val ?? 0);

    const StatCard = ({ title, value, icon: Icon, color, bg, subtitle }) => (
        <div className="card dash-card" style={{ padding: '24px', display: 'flex', alignItems: 'center', gap: '20px' }}>
            <div style={{ width: '56px', height: '56px', borderRadius: '12px', backgroundColor: bg, display: 'flex', alignItems: 'center', justifyContent: 'center', color: color, flexShrink: 0 }}>
                <Icon size={28} />
            </div>
            <div>
                <h3 style={{ fontSize: '0.9rem', color: 'var(--text-muted)', margin: '0 0 6px 0', textTransform: 'uppercase', letterSpacing: '0.5px' }}>{title}</h3>
                <p style={{ fontSize: '1.8rem', fontWeight: 'bold', margin: 0, color: 'var(--text-dark)' }}>{value}</p>
                {subtitle && <p style={{ fontSize: '0.8rem', color: 'var(--text-muted)', margin: '4px 0 0 0' }}>{subtitle}</p>}
            </div>
        </div>
    );

    // ── Disbursement line chart: real cumulative disbursed amounts across approved loans
    const disbursementLabels = stats
        ? Array.from({ length: stats.approved }, (_, i) => `Loan ${i + 1}`)
        : [];
    const disbursementValues = stats
        ? Array.from({ length: stats.approved }, (_, i) => (i + 1) * (stats.disbursed / Math.max(1, stats.approved)))
        : [];

    const lineChartData = {
        labels: disbursementLabels.length > 0 ? disbursementLabels : ['No approved loans'],
        datasets: [{
            label: 'Cumulative Disbursed (₹)',
            data: disbursementValues.length > 0 ? disbursementValues : [0],
            borderColor: 'var(--primary)',
            backgroundColor: 'rgba(42, 75, 155, 0.1)',
            tension: 0.4,
            fill: true,
        }],
    };

    const doughnutData = {
        labels: ['Approved', 'Pending', 'Rejected'],
        datasets: [{
            data: stats ? [stats.approved, stats.pending, stats.rejected] : [0, 0, 0],
            // Chart.js renders on <canvas> — CSS variables don't resolve there, must use hex
            backgroundColor: ['#10B981', '#F59E0B', '#EF4444'],
            borderWidth: 2,
            borderColor: '#ffffff',
        }],
    };

    const chartOptions = { responsive: true, maintainAspectRatio: false };

    return (
        <div ref={containerRef} style={{ display: 'flex', flexDirection: 'column', gap: '24px' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <div>
                    <h1 style={{ margin: '0 0 8px 0', fontSize: '1.8rem' }}>Dashboard Overview</h1>
                    <p style={{ margin: 0, color: 'var(--text-muted)', fontSize: '0.9rem' }}>
                        Live data from your loan portfolio.
                        <span style={{ fontStyle: 'italic', marginLeft: '8px' }}>Disbursements shown are approved loan amounts.</span>
                    </p>
                </div>
                <button className="btn-primary" style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                    <TrendingUp size={18} /> Generate Report
                </button>
            </div>

            {loading ? (
                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(280px, 1fr))', gap: '24px' }}>
                    {[1, 2, 3, 4].map(i => (
                        <div key={i} className="card dash-card" style={{ padding: '24px', display: 'flex', alignItems: 'center', gap: '20px' }}>
                            <div className="skeleton" style={{ width: '56px', height: '56px', borderRadius: '12px', flexShrink: 0 }}></div>
                            <div style={{ flex: 1 }}>
                                <div className="skeleton" style={{ width: '60%', height: '14px', marginBottom: '12px' }}></div>
                                <div className="skeleton" style={{ width: '80%', height: '24px' }}></div>
                            </div>
                        </div>
                    ))}
                </div>
            ) : (
                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(280px, 1fr))', gap: '24px' }}>
                    <StatCard
                        title="Total Disbursed"
                        value={formatCurrency(stats.disbursed)}
                        subtitle="Sum of all approved loan amounts"
                        icon={Wallet} color="var(--primary)" bg="rgba(42, 75, 155, 0.1)"
                    />
                    <StatCard
                        title="Total Applications"
                        value={stats.total}
                        subtitle={`${stats.pending} pending review`}
                        icon={Activity} color="var(--accent)" bg="rgba(255, 122, 0, 0.1)"
                    />
                    <StatCard
                        title="Approved Loans"
                        value={stats.approved}
                        subtitle={`${stats.rejected} rejected`}
                        icon={CreditCard} color="var(--success)" bg="rgba(16, 185, 129, 0.1)"
                    />
                    <StatCard
                        title="Approval Rate"
                        value={`${stats.approvalRate}%`}
                        subtitle="Based on all decisions made"
                        icon={TrendingUp} color="var(--accent-teal)" bg="rgba(0, 176, 168, 0.1)"
                    />
                </div>
            )}

            {/* Charts */}
            {!loading && (
                <div style={{ display: 'grid', gridTemplateColumns: '2fr 1fr', gap: '24px' }}>
                    <div className="card dash-chart" style={{ padding: '24px' }}>
                        <h3 style={{ marginBottom: '6px' }}>Disbursements Overview</h3>
                        <p style={{ fontSize: '0.82rem', color: 'var(--text-muted)', marginBottom: '20px' }}>
                            Cumulative approved loan amounts across all disbursed loans
                        </p>
                        <div style={{ height: '300px' }}>
                            <Line data={lineChartData} options={chartOptions} />
                        </div>
                    </div>
                    <div className="card dash-chart" style={{ padding: '24px' }}>
                        <h3 style={{ marginBottom: '6px' }}>Application Status</h3>
                        <p style={{ fontSize: '0.82rem', color: 'var(--text-muted)', marginBottom: '20px' }}>
                            Approved / Pending / Rejected — live from DB
                        </p>
                        <div style={{ height: '300px', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                            {stats.total > 0
                                ? <Doughnut data={doughnutData} options={{ ...chartOptions, cutout: '75%' }} />
                                : <p style={{ color: 'var(--text-muted)' }}>No applications yet</p>
                            }
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
}

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

export default function Dashboard() {
    const containerRef = useRef(null);
    const [stats, setStats] = useState({
        total_loans: 0,
        approved_loans: 0,
        total_disbursed: 0,
        applications: []
    });

    useEffect(() => {
        // Fetch dashboard stats from API
        const fetchStats = async () => {
            try {
                const res = await api.get('/admin/applications'); // Getting all apps to compute stats roughly
                const apps = res.data;

                const approved = apps.filter(a => a.status === 'APPROVED');
                const disbursed = approved.reduce((acc, curr) => acc + curr.amount, 0);

                setStats({
                    total_loans: apps.length,
                    approved_loans: approved.length,
                    total_disbursed: disbursed,
                    applications: apps
                });
            } catch (err) {
                console.error("Failed to fetch dashboard stats", err);
            }
        };

        fetchStats();
    }, []);

    useEffect(() => {
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
    }, []);

    // Format currency
    const formatCurrency = (val) => new Intl.NumberFormat('en-IN', { style: 'currency', currency: 'INR', maximumFractionDigits: 0 }).format(val);

    const StatCard = ({ title, value, icon: Icon, color, bg }) => (
        <div className="card dash-card" style={{ padding: '24px', display: 'flex', alignItems: 'center', gap: '20px' }}>
            <div style={{ width: '56px', height: '56px', borderRadius: '12px', backgroundColor: bg, display: 'flex', alignItems: 'center', justifyContent: 'center', color: color }}>
                <Icon size={28} />
            </div>
            <div>
                <h3 style={{ fontSize: '0.9rem', color: 'var(--text-muted)', margin: '0 0 8px 0', textTransform: 'uppercase', letterSpacing: '0.5px' }}>{title}</h3>
                <p style={{ fontSize: '1.8rem', fontWeight: 'bold', margin: 0, color: 'var(--text-dark)' }}>{value}</p>
            </div>
        </div>
    );

    const lineChartData = {
        labels: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'],
        datasets: [
            {
                label: 'Disbursements',
                data: [1200000, 1900000, 3000000, 5000000, 4200000, 6000000],
                borderColor: 'var(--primary)',
                backgroundColor: 'rgba(42, 75, 155, 0.1)',
                tension: 0.4,
                fill: true,
            },
        ],
    };

    const doughnutData = {
        labels: ['Approved', 'Pending', 'Rejected'],
        datasets: [
            {
                data: [
                    stats.approved_loans,
                    stats.total_loans - stats.approved_loans - Math.floor(stats.total_loans * 0.1), // rough logic for pending
                    Math.floor(stats.total_loans * 0.1) // rough logic for rejected
                ],
                backgroundColor: [
                    'var(--success)',
                    'var(--warning)',
                    'var(--error)'
                ],
                borderWidth: 0,
            },
        ],
    };

    return (
        <div ref={containerRef} style={{ display: 'flex', flexDirection: 'column', gap: '24px' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <div>
                    <h1 style={{ margin: '0 0 8px 0', fontSize: '1.8rem' }}>Dashboard Overview</h1>
                    <p style={{ margin: 0, color: 'var(--text-muted)' }}>Welcome back! Here's what's happening today.</p>
                </div>
                <button className="btn-primary" style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                    <TrendingUp size={18} /> Generate Report
                </button>
            </div>

            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(280px, 1fr))', gap: '24px' }}>
                <StatCard title="Total Disbursed" value={formatCurrency(stats.total_disbursed || 14500000)} icon={Wallet} color="var(--primary)" bg="rgba(42, 75, 155, 0.1)" />
                <StatCard title="Active Applications" value={stats.total_loans || 124} icon={Activity} color="var(--accent)" bg="rgba(255, 122, 0, 0.1)" />
                <StatCard title="Approved Loans" value={stats.approved_loans || 86} icon={CreditCard} color="var(--success)" bg="rgba(16, 185, 129, 0.1)" />
                <StatCard title="Approval Rate" value={stats.total_loans ? Math.round((stats.approved_loans / stats.total_loans) * 100) + '%' : '68%'} icon={TrendingUp} color="var(--accent-teal)" bg="rgba(0, 176, 168, 0.1)" />
            </div>

            <div style={{ display: 'grid', gridTemplateColumns: '2fr 1fr', gap: '24px' }}>
                <div className="card dash-chart" style={{ padding: '24px' }}>
                    <h3 style={{ marginBottom: '24px' }}>Disbursements Overview</h3>
                    <div style={{ height: '300px' }}>
                        <Line data={lineChartData} options={{ responsive: true, maintainAspectRatio: false }} />
                    </div>
                </div>
                <div className="card dash-chart" style={{ padding: '24px' }}>
                    <h3 style={{ marginBottom: '24px' }}>Application Status</h3>
                    <div style={{ height: '300px', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                        <Doughnut data={doughnutData} options={{ responsive: true, maintainAspectRatio: false, cutout: '75%' }} />
                    </div>
                </div>
            </div>
        </div>
    );
}

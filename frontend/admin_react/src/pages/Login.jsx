import React, { useEffect, useRef, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import gsap from 'gsap';
import api from '../core/api';
import { useToast } from '../components/ToastProvider';

export default function Login() {
    const containerRef = useRef(null);
    const formRef = useRef(null);
    const logoRef = useRef(null);
    const [email, setEmail] = useState('');
    const [password, setPassword] = useState('');
    const [error, setError] = useState('');
    const [loading, setLoading] = useState(false);
    const navigate = useNavigate();
    const { addToast } = useToast();

    useEffect(() => {
        const tl = gsap.timeline();
        tl.fromTo(containerRef.current, { opacity: 0 }, { opacity: 1, duration: 0.8, ease: 'power2.out' })
            .fromTo(logoRef.current, { y: -20, opacity: 0 }, { y: 0, opacity: 1, duration: 0.6, ease: 'back.out(1.7)' }, "-=0.4")
            .fromTo(formRef.current, { y: 20, opacity: 0 }, { y: 0, opacity: 1, duration: 0.6, ease: 'power2.out' }, "-=0.4");
    }, []);

    const handleLogin = async (e) => {
        e.preventDefault();
        setError('');
        setLoading(true);
        try {
            const res = await api.post('/auth/admin/login', {
                email: email,
                password: password
            });
            localStorage.setItem('adminToken', res.data.access_token);
            addToast('Successfully authenticated', 'success');
            navigate('/dashboard');
        } catch (err) {
            setError(err.response?.data?.detail || 'Login failed');
            addToast(err.response?.data?.detail || 'Login failed', 'error');
        } finally {
            setLoading(false);
        }
    };

    return (
        <div ref={containerRef} style={{ display: 'flex', minHeight: '100vh', backgroundColor: 'var(--background)' }}>
            {/* Left Decoration Panel */}
            <div style={{ flex: 1, background: 'linear-gradient(135deg, var(--primary), var(--primary-light))', display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', color: 'white', padding: '40px', textAlign: 'center' }}>
                <h1 style={{ color: 'white', fontSize: '3rem', marginBottom: '16px' }}>LENDINGKART</h1>
                <p style={{ fontSize: '1.2rem', opacity: 0.9 }}>Admin Control Center</p>
            </div>

            {/* Right Login Panel */}
            <div style={{ flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center', padding: '40px' }}>
                <div ref={formRef} className="card" style={{ width: '100%', maxWidth: '440px', padding: '48px', position: 'relative' }}>
                    <div ref={logoRef} style={{ textAlign: 'center', marginBottom: '40px' }}>
                        <h2 style={{ color: 'var(--primary)', marginBottom: '8px' }}>Welcome Back</h2>
                        <p style={{ color: 'var(--text-muted)' }}>Sign in to access the dashboard</p>
                    </div>

                    {error && (
                        <div style={{ backgroundColor: '#FEE2E2', color: '#B91C1C', padding: '12px', borderRadius: '8px', marginBottom: '20px', fontSize: '0.9rem', textAlign: 'center' }}>
                            {error}
                        </div>
                    )}

                    {/* Credential hint */}
                    <div style={{ backgroundColor: '#EFF6FF', border: '1px solid #BFDBFE', borderRadius: '8px', padding: '12px', fontSize: '0.82rem', color: '#1E40AF' }}>
                        <strong>Default credentials:</strong><br />
                        Email: <code>arjun.admin@msmelending.com</code><br />
                        Password: <code>Admin@1234</code>
                    </div>

                    <form onSubmit={handleLogin} style={{ display: 'flex', flexDirection: 'column', gap: '24px' }}>
                        <div>
                            <label style={{ display: 'block', marginBottom: '8px', fontWeight: '500', fontSize: '0.9rem' }}>Admin Email</label>
                            <input
                                type="email"
                                placeholder="arjun.admin@msmelending.com"
                                value={email}
                                onChange={(e) => setEmail(e.target.value)}
                                required
                            />
                        </div>

                        <div>
                            <label style={{ display: 'block', marginBottom: '8px', fontWeight: '500', fontSize: '0.9rem' }}>Password</label>
                            <input
                                type="password"
                                placeholder="••••••••"
                                value={password}
                                onChange={(e) => setPassword(e.target.value)}
                                required
                            />
                        </div>

                        <button type="submit" className="btn-primary" disabled={loading} style={{ marginTop: '16px', opacity: loading ? 0.7 : 1 }}>
                            {loading ? 'Authenticating...' : 'Sign In'}
                        </button>
                    </form>
                </div>
            </div>
        </div>
    );
}

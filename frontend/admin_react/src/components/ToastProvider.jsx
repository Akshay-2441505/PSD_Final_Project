import React, { createContext, useContext, useState, useRef, useEffect } from 'react';
import gsap from 'gsap';
import { BadgeCheck, Info, XCircle } from 'lucide-react';

const ToastContext = createContext();

export const useToast = () => useContext(ToastContext);

export const ToastProvider = ({ children }) => {
    const [toasts, setToasts] = useState([]);

    const addToast = (message, type = 'success') => {
        const id = Math.random().toString(36).substr(2, 9);
        setToasts(prev => [...prev, { id, message, type }]);

        // Auto remove
        setTimeout(() => removeToast(id), 4000);
    };

    const removeToast = (id) => {
        setToasts(prev => prev.filter(t => t.id !== id));
    };

    return (
        <ToastContext.Provider value={{ addToast }}>
            {children}
            <ToastContainer toasts={toasts} removeToast={removeToast} />
        </ToastContext.Provider>
    );
};

const ToastContainer = ({ toasts, removeToast }) => {
    return (
        <div style={{
            position: 'fixed',
            bottom: '24px',
            right: '24px',
            display: 'flex',
            flexDirection: 'column',
            gap: '12px',
            zIndex: 9999
        }}>
            {toasts.map(toast => (
                <ToastItem key={toast.id} toast={toast} removeToast={removeToast} />
            ))}
        </div>
    );
};

const ToastItem = ({ toast, removeToast }) => {
    const nodeRef = useRef(null);

    useEffect(() => {
        gsap.fromTo(nodeRef.current,
            { x: 50, opacity: 0 },
            { x: 0, opacity: 1, duration: 0.3, ease: 'back.out(1.2)' }
        );
    }, []);

    const handleClose = () => {
        gsap.to(nodeRef.current, {
            x: 50, opacity: 0, duration: 0.3, ease: 'power2.in', onComplete: () => removeToast(toast.id)
        });
    };

    const getIcon = () => {
        switch (toast.type) {
            case 'success': return <BadgeCheck size={20} color="var(--success)" />;
            case 'error': return <XCircle size={20} color="var(--error)" />;
            default: return <Info size={20} color="var(--primary)" />;
        }
    };

    return (
        <div
            ref={nodeRef}
            className="card"
            style={{
                display: 'flex',
                alignItems: 'center',
                gap: '12px',
                padding: '16px 20px',
                minWidth: '300px',
                background: 'white',
                borderLeft: `4px solid var(--${toast.type === 'error' ? 'error' : toast.type === 'info' ? 'primary' : 'success'})`,
                boxShadow: '0 10px 15px -3px rgba(0,0,0,0.1)'
            }}
        >
            {getIcon()}
            <p style={{ margin: 0, flex: 1, fontSize: '14px', fontWeight: '500', color: 'var(--text-dark)' }}>{toast.message}</p>
            <button
                onClick={handleClose}
                style={{ background: 'transparent', border: 'none', cursor: 'pointer', color: 'var(--text-muted)' }}
            >
                <XCircle size={16} />
            </button>
        </div>
    );
};

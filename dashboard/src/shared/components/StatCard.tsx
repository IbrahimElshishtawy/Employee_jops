import React from 'react';

interface StatCardProps {
  title: string;
  value: string | number;
  subtitle?: string;
  icon: React.ReactNode;
  trend?: {
    value: string;
    isPositive?: boolean;
  };
  color?: string;
}

export const StatCard: React.FC<StatCardProps> = ({
  title,
  value,
  subtitle,
  icon,
  trend,
  color = 'var(--primary)',
}) => {
  return (
    <div className="card card-hover flex flex-col justify-between" style={{ minHeight: '120px' }}>
      <div className="flex items-center justify-between">
        <span style={{ fontSize: '0.85rem', fontWeight: 600, color: 'var(--text-secondary)' }}>
          {title}
        </span>
        <div
          style={{
            padding: '0.5rem',
            borderRadius: 'var(--radius-sm)',
            backgroundColor: 'var(--bg-tertiary)',
            color,
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
          }}
        >
          {icon}
        </div>
      </div>
      <div style={{ marginTop: '0.75rem' }}>
        <h2 style={{ fontSize: '1.75rem', fontWeight: 800 }}>{value}</h2>
        {(subtitle || trend) && (
          <div className="flex items-center gap-2" style={{ marginTop: '0.25rem' }}>
            {trend && (
              <span
                style={{
                  fontSize: '0.75rem',
                  fontWeight: 700,
                  color: trend.isPositive ? 'var(--success)' : 'var(--danger)',
                }}
              >
                {trend.value}
              </span>
            )}
            {subtitle && (
              <span style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>
                {subtitle}
              </span>
            )}
          </div>
        )}
      </div>
    </div>
  );
};

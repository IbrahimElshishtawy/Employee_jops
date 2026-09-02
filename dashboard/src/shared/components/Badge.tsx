import React from 'react';

export type BadgeVariant = 'primary' | 'success' | 'warning' | 'danger' | 'info' | 'neutral';

interface BadgeProps {
  children: React.ReactNode;
  variant?: BadgeVariant;
  className?: string;
}

export const Badge: React.FC<BadgeProps> = ({ children, variant = 'neutral', className = '' }) => {
  return <span className={`badge badge-${variant} ${className}`}>{children}</span>;
};

export const StatusBadge: React.FC<{ status: string }> = ({ status }) => {
  const getVariant = (st: string): BadgeVariant => {
    switch (st?.toUpperCase()) {
      case 'ACTIVE':
      case 'PRESENT':
      case 'APPROVED':
      case 'FINALIZED':
      case 'PAID':
      case 'PUBLISHED':
        return 'success';
      case 'PENDING':
      case 'LATE':
      case 'REVIEW':
      case 'CALCULATED':
      case 'PARTIALLY_PAID':
        return 'warning';
      case 'INACTIVE':
      case 'SUSPENDED':
      case 'ABSENT':
      case 'REJECTED':
      case 'CANCELLED':
      case 'LOCKED':
        return 'danger';
      case 'EARLY_LEAVE':
      case 'ON_LEAVE':
      case 'OPEN':
        return 'info';
      default:
        return 'neutral';
    }
  };

  return <Badge variant={getVariant(status)}>{status?.replace(/_/g, ' ')}</Badge>;
};

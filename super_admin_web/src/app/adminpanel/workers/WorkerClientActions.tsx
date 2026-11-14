'use client';

import { Button } from '@/components/ui/button';
import { CheckCircle, XCircle } from 'lucide-react';
import { useToast } from '@/hooks/use-toast';
import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { Loader2 } from 'lucide-react';

export function WorkerClientActions({ workerId, isVerified }: { workerId: string, isVerified: boolean }) {
  const { toast } = useToast();
  const router = useRouter();
  const [isLoading, setIsLoading] = useState(false);

  const handleVerify = async (verifyStatus: boolean) => {
    setIsLoading(true);
    try {
      const res = await fetch('/api/admin/workers/action', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ workerId, isVerified: verifyStatus })
      });
      const response = await res.json();
      if (!res.ok) throw new Error(response.error || 'Action failed');
      
      toast({ title: 'Success', description: 'Worker verification updated.' });
      router.refresh();
    } catch (error) {
      toast({ title: 'Error', description: error instanceof Error ? error.message : 'Failed to update worker.', variant: 'destructive' });
    } finally {
      setIsLoading(false);
    }
  };

  if (isVerified) {
    return (
      <Button aria-label="Revoke worker verification" title="Revoke worker verification" disabled={isLoading} onClick={() => handleVerify(false)} variant="ghost" size="icon" className="text-sb-error hover:text-sb-error hover:bg-sb-error-subtle">
        {isLoading ? <Loader2 className="h-4 w-4 animate-spin" /> : <XCircle className="h-4 w-4" />}
      </Button>
    );
  }

  return (
    <Button aria-label="Verify worker" title="Verify worker" disabled={isLoading} onClick={() => handleVerify(true)} variant="ghost" size="icon" className="text-sb-success hover:text-sb-on-success-subtle hover:bg-sb-success-subtle">
      {isLoading ? <Loader2 className="h-4 w-4 animate-spin" /> : <CheckCircle className="h-4 w-4" />}
    </Button>
  );
}

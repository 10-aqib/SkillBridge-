'use client';

import { Button } from '@/components/ui/button';
import { CheckCircle, XCircle } from 'lucide-react';
import { useToast } from '@/hooks/use-toast';
import { useState } from 'react';

export function WorkerClientActions({ workerId, isVerified }: { workerId: string, isVerified: boolean }) {
  const { toast } = useToast();
  const [isLoading, setIsLoading] = useState(false);

  const handleVerify = async (verifyStatus: boolean) => {
    setIsLoading(true);
    try {
      const res = await fetch('/api/admin/workers/action', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ workerId, isVerified: verifyStatus })
      });
      if (!res.ok) throw new Error('Action failed');
      
      toast({ title: 'Success', description: 'Worker verification updated. Please refresh.' });
      // Optionally router.refresh() here if router was passed
    } catch (error) {
      toast({ title: 'Error', description: 'Failed to update worker.', variant: 'destructive' });
    } finally {
      setIsLoading(false);
    }
  };

  if (isVerified) {
    return (
      <Button disabled={isLoading} onClick={() => handleVerify(false)} variant="ghost" size="icon" className="text-red-500 hover:text-red-600 hover:bg-red-50">
        <XCircle className="h-4 w-4" />
      </Button>
    );
  }

  return (
    <Button disabled={isLoading} onClick={() => handleVerify(true)} variant="ghost" size="icon" className="text-emerald-500 hover:text-emerald-600 hover:bg-emerald-50">
      <CheckCircle className="h-4 w-4" />
    </Button>
  );
}

'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { Button } from '@/components/ui/button';
import { Loader2, Ban, CheckCircle, Trash2 } from 'lucide-react';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { useToast } from "@/hooks/use-toast";

export function UserClientActions({ 
  uid, 
  isDisabled 
}: { 
  uid: string, 
  isDisabled: boolean 
}) {
  const [isLoading, setIsLoading] = useState(false);
  const [reason, setReason] = useState('');
  const [isOpen, setIsOpen] = useState(false);
  const [actionType, setActionType] = useState<'suspend' | 'restore' | 'delete' | null>(null);
  
  const router = useRouter();
  const { toast } = useToast();

  const handleAction = async () => {
    if (!actionType) return;
    
    setIsLoading(true);
    
    try {
      const res = await fetch('/api/admin/users/action', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ uid, action: actionType, reason }),
      });

      const data = await res.json();

      if (res.ok) {
        toast({
          title: "Success",
          description: data.message,
        });
        setIsOpen(false);
        router.refresh();
      } else {
        toast({
          title: "Error",
          description: data.error,
          variant: "destructive",
        });
      }
    } catch (error: any) {
      toast({
        title: "Error",
        description: error.message || "An unexpected error occurred",
        variant: "destructive",
      });
    } finally {
      setIsLoading(false);
      setReason('');
      setActionType(null);
    }
  };

  const openDialog = (type: 'suspend' | 'restore' | 'delete') => {
    setActionType(type);
    setIsOpen(true);
  };

  return (
    <div className="flex flex-wrap gap-2">
      {!isDisabled ? (
        <Button variant="destructive" onClick={() => openDialog('suspend')}>
          <Ban className="mr-2 h-4 w-4" /> Suspend
        </Button>
      ) : (
        <Button variant="outline" className="border-emerald-500 text-emerald-600 hover:bg-emerald-50" onClick={() => openDialog('restore')}>
          <CheckCircle className="mr-2 h-4 w-4" /> Restore
        </Button>
      )}

      <Button variant="outline" className="text-red-500 border-red-200 hover:bg-red-50" onClick={() => openDialog('delete')}>
        <Trash2 className="mr-2 h-4 w-4" /> Delete
      </Button>

      <Dialog open={isOpen} onOpenChange={setIsOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle className="capitalize">{actionType} User</DialogTitle>
            <DialogDescription>
              {actionType === 'delete' 
                ? "This action is permanent and cannot be undone." 
                : `Are you sure you want to ${actionType} this user?`}
            </DialogDescription>
          </DialogHeader>
          
          <div className="space-y-4 py-4">
            <div className="space-y-2">
              <Label htmlFor="reason">Reason (Required for Audit Log)</Label>
              <Input
                id="reason"
                placeholder="e.g. Violation of terms"
                value={reason}
                onChange={(e) => setReason(e.target.value)}
              />
            </div>
          </div>
          
          <DialogFooter>
            <Button variant="outline" onClick={() => setIsOpen(false)} disabled={isLoading}>
              Cancel
            </Button>
            <Button 
              variant={actionType === 'restore' ? 'default' : 'destructive'} 
              onClick={handleAction} 
              disabled={isLoading || !reason.trim()}
            >
              {isLoading ? <Loader2 className="mr-2 h-4 w-4 animate-spin" /> : null}
              Confirm {actionType}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}

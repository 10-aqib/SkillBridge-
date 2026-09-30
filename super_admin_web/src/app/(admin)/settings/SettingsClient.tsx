'use client';

import { useState } from 'react';
import { 
  Sliders, 
  ShieldAlert, 
  DollarSign, 
  MapPin, 
  Bell, 
  Lock, 
  Save, 
  CheckCircle2, 
  RefreshCw,
  Info
} from 'lucide-react';
import { Switch } from '@/components/ui/switch';
import { Label } from '@/components/ui/label';
import { Input } from '@/components/ui/input';
import { Button } from '@/components/ui/button';
import { useToast } from '@/hooks/use-toast';

export function SettingsClient() {
  const { toast } = useToast();
  const [isSaving, setIsSaving] = useState(false);

  // Platform state
  const [maintenanceMode, setMaintenanceMode] = useState(false);
  const [workerRegistrations, setWorkerRegistrations] = useState(true);
  const [cnicStrictVerify, setCnicStrictVerify] = useState(true);

  // Financial state
  const [commissionRate, setCommissionRate] = useState('15');
  const [withdrawalFee, setWithdrawalFee] = useState('50');
  const [escrowHoldDays, setEscrowHoldDays] = useState('3');

  // Cities
  const [cityIslamabad, setCityIslamabad] = useState(true);
  const [cityRawalpindi, setCityRawalpindi] = useState(true);
  const [cityLahore, setCityLahore] = useState(true);
  const [cityKarachi, setCityKarachi] = useState(true);
  const [cityPeshawar, setCityPeshawar] = useState(false);

  // Security
  const [requireMFA, setRequireMFA] = useState(true);
  const [sessionTimeout, setSessionTimeout] = useState('60');
  const [alertEmail, setAlertEmail] = useState('ak9024706@gmail.com');

  const handleSave = () => {
    setIsSaving(true);
    setTimeout(() => {
      setIsSaving(false);
      toast({
        title: 'Settings Saved',
        description: 'Platform configurations have been synchronized successfully.',
      });
    }, 600);
  };

  return (
    <div className="space-y-6">
      {/* Settings Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        
        {/* Card 1: Platform Controls */}
        <div className="bg-white rounded-2xl border border-[#E8EFF9] figma-card-shadow p-6 space-y-5">
          <div className="flex items-center gap-3 border-b border-[#F0F4FA] pb-4">
            <div className="w-10 h-10 rounded-xl bg-blue-50 text-[#2F80ED] flex items-center justify-center">
              <Sliders className="w-5 h-5" />
            </div>
            <div>
              <h2 className="text-base font-bold text-slate-800">System & Governance</h2>
              <p className="text-xs text-slate-400">Global toggles for platform accessibility</p>
            </div>
          </div>

          <div className="space-y-4 pt-1">
            <div className="flex items-center justify-between p-3 rounded-xl bg-[#F8FAFD] border border-slate-100">
              <div className="space-y-0.5">
                <div className="flex items-center gap-2">
                  <Label className="text-xs font-bold text-slate-800">Maintenance Mode</Label>
                  {maintenanceMode && (
                    <span className="bg-red-100 text-red-700 text-[10px] font-bold px-1.5 py-0.2 rounded">HALTED</span>
                  )}
                </div>
                <p className="text-[11px] text-slate-500">
                  Suspend client & worker access while retaining super admin access.
                </p>
              </div>
              <Switch checked={maintenanceMode} onCheckedChange={setMaintenanceMode} />
            </div>

            <div className="flex items-center justify-between p-3 rounded-xl bg-[#F8FAFD] border border-slate-100">
              <div className="space-y-0.5">
                <Label className="text-xs font-bold text-slate-800">Worker Registrations</Label>
                <p className="text-[11px] text-slate-500">
                  Allow new technician profiles and skill submissions.
                </p>
              </div>
              <Switch checked={workerRegistrations} onCheckedChange={setWorkerRegistrations} />
            </div>

            <div className="flex items-center justify-between p-3 rounded-xl bg-[#F8FAFD] border border-slate-100">
              <div className="space-y-0.5">
                <Label className="text-xs font-bold text-slate-800">Mandatory CNIC Verification</Label>
                <p className="text-[11px] text-slate-500">
                  Require valid Pakistani National ID approval before bidding on jobs.
                </p>
              </div>
              <Switch checked={cnicStrictVerify} onCheckedChange={setCnicStrictVerify} />
            </div>
          </div>
        </div>

        {/* Card 2: Financial & Escrow Policy */}
        <div className="bg-white rounded-2xl border border-[#E8EFF9] figma-card-shadow p-6 space-y-5">
          <div className="flex items-center gap-3 border-b border-[#F0F4FA] pb-4">
            <div className="w-10 h-10 rounded-xl bg-emerald-50 text-emerald-600 flex items-center justify-center">
              <DollarSign className="w-5 h-5" />
            </div>
            <div>
              <h2 className="text-base font-bold text-slate-800">Financial Rules & Commission</h2>
              <p className="text-xs text-slate-400">Escrow retention and fee percentages</p>
            </div>
          </div>

          <div className="space-y-4 pt-1">
            <div className="space-y-1.5">
              <Label className="text-xs font-bold text-slate-800">Platform Commission Rate (%)</Label>
              <div className="relative">
                <Input 
                  type="number"
                  value={commissionRate}
                  onChange={(e) => setCommissionRate(e.target.value)}
                  className="h-10 rounded-xl bg-[#F4F7FE] border-none text-xs font-bold text-slate-800 pr-8"
                />
                <span className="absolute right-3.5 top-1/2 -translate-y-1/2 text-xs font-bold text-slate-400">%</span>
              </div>
              <p className="text-[10px] text-slate-400">Standard commission deducted from completed contracts.</p>
            </div>

            <div className="grid grid-cols-2 gap-3">
              <div className="space-y-1.5">
                <Label className="text-xs font-bold text-slate-800">Withdrawal Fee (Rs.)</Label>
                <div className="relative">
                  <Input 
                    type="number"
                    value={withdrawalFee}
                    onChange={(e) => setWithdrawalFee(e.target.value)}
                    className="h-10 rounded-xl bg-[#F4F7FE] border-none text-xs font-bold text-slate-800"
                  />
                </div>
              </div>

              <div className="space-y-1.5">
                <Label className="text-xs font-bold text-slate-800">Escrow Clearance (Days)</Label>
                <div className="relative">
                  <Input 
                    type="number"
                    value={escrowHoldDays}
                    onChange={(e) => setEscrowHoldDays(e.target.value)}
                    className="h-10 rounded-xl bg-[#F4F7FE] border-none text-xs font-bold text-slate-800"
                  />
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Card 3: Regional Coverage */}
        <div className="bg-white rounded-2xl border border-[#E8EFF9] figma-card-shadow p-6 space-y-5">
          <div className="flex items-center gap-3 border-b border-[#F0F4FA] pb-4">
            <div className="w-10 h-10 rounded-xl bg-purple-50 text-purple-600 flex items-center justify-center">
              <MapPin className="w-5 h-5" />
            </div>
            <div>
              <h2 className="text-base font-bold text-slate-800">Regional Service Coverage</h2>
              <p className="text-xs text-slate-400">Manage active service zones in Pakistan</p>
            </div>
          </div>

          <div className="grid grid-cols-2 gap-3 pt-1">
            <div className="flex items-center justify-between p-3 rounded-xl bg-[#F8FAFD] border border-slate-100">
              <span className="text-xs font-semibold text-slate-700">Islamabad (ICT)</span>
              <Switch checked={cityIslamabad} onCheckedChange={setCityIslamabad} />
            </div>

            <div className="flex items-center justify-between p-3 rounded-xl bg-[#F8FAFD] border border-slate-100">
              <span className="text-xs font-semibold text-slate-700">Rawalpindi</span>
              <Switch checked={cityRawalpindi} onCheckedChange={setCityRawalpindi} />
            </div>

            <div className="flex items-center justify-between p-3 rounded-xl bg-[#F8FAFD] border border-slate-100">
              <span className="text-xs font-semibold text-slate-700">Lahore</span>
              <Switch checked={cityLahore} onCheckedChange={setCityLahore} />
            </div>

            <div className="flex items-center justify-between p-3 rounded-xl bg-[#F8FAFD] border border-slate-100">
              <span className="text-xs font-semibold text-slate-700">Karachi</span>
              <Switch checked={cityKarachi} onCheckedChange={setCityKarachi} />
            </div>

            <div className="flex items-center justify-between p-3 rounded-xl bg-[#F8FAFD] border border-slate-100 col-span-2">
              <span className="text-xs font-semibold text-slate-700">Peshawar (Coming Soon)</span>
              <Switch checked={cityPeshawar} onCheckedChange={setCityPeshawar} />
            </div>
          </div>
        </div>

        {/* Card 4: Security & Super Admin Alerts */}
        <div className="bg-white rounded-2xl border border-[#E8EFF9] figma-card-shadow p-6 space-y-5">
          <div className="flex items-center gap-3 border-b border-[#F0F4FA] pb-4">
            <div className="w-10 h-10 rounded-xl bg-amber-50 text-amber-600 flex items-center justify-center">
              <Lock className="w-5 h-5" />
            </div>
            <div>
              <h2 className="text-base font-bold text-slate-800">Security & Alerts</h2>
              <p className="text-xs text-slate-400">Super admin notifications and session timeouts</p>
            </div>
          </div>

          <div className="space-y-4 pt-1">
            <div className="space-y-1.5">
              <Label className="text-xs font-bold text-slate-800">Alert Dispatch Email</Label>
              <Input 
                type="email"
                value={alertEmail}
                onChange={(e) => setAlertEmail(e.target.value)}
                className="h-10 rounded-xl bg-[#F4F7FE] border-none text-xs text-slate-800 font-medium"
              />
            </div>

            <div className="flex items-center justify-between p-3 rounded-xl bg-[#F8FAFD] border border-slate-100">
              <div className="space-y-0.5">
                <Label className="text-xs font-bold text-slate-800">Enforce Multi-Factor (MFA)</Label>
                <p className="text-[11px] text-slate-500">Require OTP code for administrative sign-in.</p>
              </div>
              <Switch checked={requireMFA} onCheckedChange={setRequireMFA} />
            </div>
          </div>
        </div>
      </div>

      {/* Save Action Bar */}
      <div className="bg-white rounded-2xl border border-[#E8EFF9] figma-card-shadow p-4 flex items-center justify-between">
        <div className="flex items-center gap-2 text-xs text-slate-500">
          <Info className="w-4 h-4 text-[#2F80ED]" />
          <span>Changes are recorded in the Immutable Audit Ledger.</span>
        </div>

        <Button
          onClick={handleSave}
          disabled={isSaving}
          className="bg-[#2F80ED] hover:bg-blue-600 text-white rounded-xl text-xs font-semibold px-5 h-10 shadow-md shadow-blue-500/20 flex items-center gap-2"
        >
          {isSaving ? <RefreshCw className="w-4 h-4 animate-spin" /> : <Save className="w-4 h-4" />}
          <span>{isSaving ? 'Synchronizing...' : 'Save Changes'}</span>
        </Button>
      </div>
    </div>
  );
}

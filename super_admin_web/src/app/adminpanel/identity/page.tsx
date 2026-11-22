import { IdentityClient } from './IdentityClient';
import { IdentityService } from '@/lib/services/identity.service';

export const dynamic = 'force-dynamic';

export default async function IdentityPage() {
  const requests = await IdentityService.getRequests();

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl lg:text-3xl font-extrabold text-sb-text tracking-tight">Identity Verification</h1>
        <p className="text-xs text-sb-text-secondary mt-0.5">
          NADRA fingerprint verification requests for workers and hirers. Staff can flag a request for review or ask
          the person to verify again, but can never mark anyone NADRA verified. No fingerprints or full CNICs are stored
          or shown.
        </p>
      </div>
      <IdentityClient initialRequests={requests} />
    </div>
  );
}

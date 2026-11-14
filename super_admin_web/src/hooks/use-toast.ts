type ToastProps = {
  title: string;
  description?: string;
  variant?: 'default' | 'destructive';
};

export function useToast() {
  return {
    toast: (props: ToastProps) => {
      console.log('Toast triggered:', props);
    }
  };
}
